import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/ota_service.dart';

// ── Check ─────────────────────────────────────────────────────────────────────

/// Runs once on first watch. Returns OtaResult if action needed, null otherwise.
final otaCheckProvider = FutureProvider<OtaResult?>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final code = int.tryParse(info.buildNumber) ?? 0;
  return OtaService().checkForUpdate(code);
});

// ── Banner dismiss ─────────────────────────────────────────────────────────────

final otaDismissedProvider = StateProvider<bool>((_) => false);

// ── Download state ─────────────────────────────────────────────────────────────

enum OtaStatus { idle, downloading, failed, installing }

class OtaDownloadState {
  final OtaStatus status;
  final double progress; // 0.0–1.0 during download
  const OtaDownloadState({this.status = OtaStatus.idle, this.progress = 0});
}

class OtaDownloadNotifier extends Notifier<OtaDownloadState> {
  @override
  OtaDownloadState build() => const OtaDownloadState();

  Future<void> start(OtaRelease target) async {
    state = const OtaDownloadState(status: OtaStatus.downloading);

    final path = await OtaService().downloadUpdate(
      target,
      onProgress: (p) {
        state = OtaDownloadState(status: OtaStatus.downloading, progress: p);
      },
    );

    if (path == null) {
      state = const OtaDownloadState(status: OtaStatus.failed);
      return;
    }

    state = const OtaDownloadState(status: OtaStatus.installing);
    try {
      await OtaService().triggerInstall(path);
    } on MissingPluginException {
      // Running on non-Android platform (e.g. desktop dev) — ignore
    } catch (_) {
      state = const OtaDownloadState(status: OtaStatus.failed);
    }
  }

  void reset() => state = const OtaDownloadState();
}

final otaDownloadProvider =
    NotifierProvider<OtaDownloadNotifier, OtaDownloadState>(OtaDownloadNotifier.new);
