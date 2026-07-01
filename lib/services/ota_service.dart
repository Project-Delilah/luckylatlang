import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _releaseJsonUrl =
    'https://raw.githubusercontent.com/Project-Delilah/ota_updates/main/release.json';

// Maps dart:ffi ABI to the arch string used in release.json / APK filenames
String get _deviceArch {
  return switch (Abi.current()) {
    Abi.androidArm64 => 'arm64-v8a',
    Abi.androidArm   => 'armeabi-v7a',
    Abi.androidX64   => 'x86_64',
    _                => 'arm64-v8a', // safe fallback — most modern devices
  };
}

class OtaApk {
  final String url;
  final String sha256;
  const OtaApk({required this.url, required this.sha256});

  factory OtaApk.fromJson(Map<String, dynamic> j) => OtaApk(
        url: j['url'] as String,
        sha256: (j['sha256'] as String).toLowerCase(),
      );
}

class OtaRelease {
  final int versionCode;
  final String version;
  final String changelog;
  final bool forceRollback;
  final Map<String, OtaApk> apks;
  final OtaRelease? rollback;

  const OtaRelease({
    required this.versionCode,
    required this.version,
    required this.changelog,
    required this.forceRollback,
    required this.apks,
    this.rollback,
  });

  factory OtaRelease.fromJson(Map<String, dynamic> j) {
    final apksRaw = (j['apks'] as Map<String, dynamic>?) ?? {};
    return OtaRelease(
      versionCode: j['versionCode'] as int,
      version: j['version'] as String,
      changelog: (j['changelog'] as String?) ?? '',
      forceRollback: (j['forceRollback'] as bool?) ?? false,
      apks: apksRaw.map((k, v) => MapEntry(k, OtaApk.fromJson(v as Map<String, dynamic>))),
      rollback: j['rollback'] != null
          ? OtaRelease.fromJson(j['rollback'] as Map<String, dynamic>)
          : null,
    );
  }

  OtaApk? get apkForDevice => apks[_deviceArch] ?? apks['arm64-v8a'];
}

class OtaResult {
  final OtaRelease release; // the manifest that was fetched
  final OtaRelease target;  // the release to actually install (may be rollback)
  final bool isRollback;
  const OtaResult({required this.release, required this.target, required this.isRollback});
}

class OtaService {
  static final _channel = const MethodChannelOta._();

  /// Fetches release.json and returns an [OtaResult] if action is needed.
  /// Returns null if up-to-date or on any network/parse failure.
  Future<OtaResult?> checkForUpdate(int currentVersionCode) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(_releaseJsonUrl));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) { client.close(); return null; }
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final j = jsonDecode(body) as Map<String, dynamic>;
      final release = OtaRelease.fromJson(j);

      // Force rollback: admin flagged a bad release — push users to previous version
      if (release.forceRollback && release.rollback != null) {
        final rb = release.rollback!;
        if (currentVersionCode > rb.versionCode && rb.apkForDevice != null) {
          return OtaResult(release: release, target: rb, isRollback: true);
        }
      }

      // Normal update
      if (release.versionCode > currentVersionCode && release.apkForDevice != null) {
        return OtaResult(release: release, target: release, isRollback: false);
      }

      return null;
    } catch (_) {
      return null; // network down, malformed JSON, etc. — do nothing
    }
  }

  /// Downloads the APK for [target], verifying SHA-256.
  /// Idempotent: skips download if a verified file already exists in cache.
  /// Returns the local file path on success, null on any failure.
  Future<String?> downloadUpdate(
    OtaRelease target, {
    void Function(double progress)? onProgress,
  }) async {
    final apk = target.apkForDevice;
    if (apk == null) return null;

    final dir = await getApplicationCacheDirectory();
    final tmpPath  = '${dir.path}/ota_update.apk.tmp';
    final finalPath = '${dir.path}/ota_update_v${target.versionCode}.apk';

    // Idempotency: if a verified file for this version already exists, skip download
    final existing = File(finalPath);
    if (await existing.exists()) {
      final digest = await _sha256File(existing);
      if (digest == apk.sha256) return finalPath;
      await existing.delete(); // stale / corrupted — re-download
    }

    // Clean up any previous partial download
    final tmp = File(tmpPath);
    if (await tmp.exists()) await tmp.delete();

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(apk.url));
      final res = await req.close();
      if (res.statusCode != 200) { client.close(); return null; }

      final total = res.contentLength;
      var received = 0;
      final sink = tmp.openWrite();

      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
      client.close();

      // Verify integrity before making the file visible to the installer
      final digest = await _sha256File(tmp);
      if (digest != apk.sha256) {
        await tmp.delete();
        return null; // hash mismatch — corrupted download
      }

      // Atomic rename: file only appears at finalPath after full verification
      await tmp.rename(finalPath);
      return finalPath;
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      return null;
    }
  }

  Future<void> triggerInstall(String apkPath) => _channel.install(apkPath);

  Future<String> _sha256File(File f) async {
    final bytes = await f.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}

// ── Thin MethodChannel wrapper — triggers Android's package installer via FileProvider
class MethodChannelOta {
  static final _ch = const MethodChannel('com.isg32.luckylatlang/ota');
  const MethodChannelOta._();

  Future<void> install(String path) =>
      _ch.invokeMethod('installApk', {'path': path});
}
