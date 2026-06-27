import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/birth_profile.dart';

class ProfileStorage {
  static const _key = 'birth_profile';

  final SharedPreferences _prefs;
  ProfileStorage(this._prefs);

  BirthProfile? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return BirthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(BirthProfile profile) =>
      _prefs.setString(_key, jsonEncode(profile.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}
