import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/db/city_db.dart';
import '../models/city_spot.dart';
import '../services/city_service.dart';
import 'astro_provider.dart';

final cityDbProvider = FutureProvider<CityDb>((ref) => CityDb.open());

final cityServiceProvider = Provider<CityService?>((ref) {
  final db = ref.watch(cityDbProvider);
  return db.valueOrNull != null ? CityService(db.valueOrNull!) : null;
});

final citySpotsProvider = FutureProvider<List<CitySpot>>((ref) async {
  final astroAsync = ref.watch(astroResultProvider);
  final astro = astroAsync.valueOrNull;
  if (astro == null) return [];

  final service = ref.watch(cityServiceProvider);
  if (service == null) return [];

  return service.computeSpots(astro);
});

// Currently selected city for the detail panel
final selectedCityProvider = StateProvider<CitySpot?>((ref) => null);

// Selected country filter (null = all countries)
final countryFilterProvider = StateProvider<String?>((ref) => null);

// Unique countries derived from computed spots, sorted by name
final availableCountriesProvider = Provider<List<({String code, String name})>>((ref) {
  final spots = ref.watch(citySpotsProvider).valueOrNull ?? [];
  final seen = <String>{};
  final result = <({String code, String name})>[];
  for (final s in spots) {
    if (seen.add(s.countryCode)) {
      result.add((code: s.countryCode, name: s.countryName));
    }
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
});

// Tapped map point (lat/lng) for blank-spot scoring
final tappedPointProvider = StateProvider<LatLng?>((ref) => null);

// Synchronously score the tapped point against planet lines
final tappedPointSpotProvider = Provider<CitySpot?>((ref) {
  final point = ref.watch(tappedPointProvider);
  if (point == null) return null;
  final astro = ref.watch(astroResultProvider).valueOrNull;
  if (astro == null) return null;
  final service = ref.watch(cityServiceProvider);
  if (service == null) return null;
  return service.scorePoint(astro, point);
});

// Spots filtered by selected country
final filteredSpotsProvider = Provider<List<CitySpot>>((ref) {
  final spots = ref.watch(citySpotsProvider).valueOrNull ?? [];
  final country = ref.watch(countryFilterProvider);
  if (country == null) return spots;
  return spots.where((s) => s.countryCode == country).toList();
});
