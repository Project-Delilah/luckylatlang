import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/profile_storage.dart';
import '../models/birth_profile.dart';

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
    await ref.read(profileStorageProvider).saveProfile(profile);
    state = profile;
    ref.invalidate(profileListProvider);
  }

  Future<void> setActive(String id) async {
    await ref.read(profileStorageProvider).setActive(id);
    state = ref.read(profileStorageProvider).load();
    ref.invalidate(profileListProvider);
  }

  Future<void> clear() async {
    await ref.read(profileStorageProvider).clear();
    state = null;
    ref.invalidate(profileListProvider);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, BirthProfile?>(
  ProfileNotifier.new,
);

class ProfileListNotifier extends Notifier<List<BirthProfile>> {
  @override
  List<BirthProfile> build() => ref.read(profileStorageProvider).loadAll();
}

final profileListProvider = NotifierProvider<ProfileListNotifier, List<BirthProfile>>(
  ProfileListNotifier.new,
);
