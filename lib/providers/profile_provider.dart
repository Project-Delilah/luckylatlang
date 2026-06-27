import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/profile_storage.dart';
import '../models/birth_profile.dart';

// Initialized at app start in main.dart via ProviderScope overrides
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

final profileStorageProvider = Provider<ProfileStorage>((ref) {
  return ProfileStorage(ref.watch(sharedPreferencesProvider));
});

class ProfileNotifier extends Notifier<BirthProfile?> {
  @override
  BirthProfile? build() => ref.read(profileStorageProvider).load();

  Future<void> save(BirthProfile profile) async {
    await ref.read(profileStorageProvider).save(profile);
    state = profile;
  }

  Future<void> clear() async {
    await ref.read(profileStorageProvider).clear();
    state = null;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, BirthProfile?>(
  ProfileNotifier.new,
);
