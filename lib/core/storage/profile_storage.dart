import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/birth_profile.dart';

class ProfileStorage {
  static const _listKey = 'birth_profiles';
  static const _activeKey = 'active_profile_id';
  static const _legacyKey = 'birth_profile';

  final SharedPreferences _prefs;
  ProfileStorage(this._prefs);

  List<BirthProfile> loadAll() {
    final raw = _prefs.getString(_listKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      return list.map((j) => BirthProfile.fromJson(j as Map<String, dynamic>)).toList();
    }
    // Migrate legacy single profile
    final legacy = _prefs.getString(_legacyKey);
    if (legacy != null) {
      return [BirthProfile.fromJson(jsonDecode(legacy) as Map<String, dynamic>)];
    }
    return [];
  }

  BirthProfile? load() {
    final all = loadAll();
    if (all.isEmpty) return null;
    final activeId = _prefs.getString(_activeKey);
    if (activeId != null) {
      try { return all.firstWhere((p) => p.id == activeId); } catch (_) {}
    }
    return all.last;
  }

  Future<void> saveProfile(BirthProfile profile) async {
    final all = loadAll();
    final idx = all.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      all[idx] = profile;
    } else {
      all.add(profile);
    }
    await _prefs.setString(_listKey, jsonEncode(all.map((p) => p.toJson()).toList()));
    await _prefs.setString(_activeKey, profile.id);
  }

  Future<void> setActive(String id) => _prefs.setString(_activeKey, id);

  Future<void> save(BirthProfile profile) => saveProfile(profile);

  Future<void> clear() async {
    await _prefs.remove(_listKey);
    await _prefs.remove(_activeKey);
  }
}
