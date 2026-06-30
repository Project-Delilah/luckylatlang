import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/natal_chart.dart';
import '../models/planet_line.dart';
import '../services/astro_service.dart';
import 'profile_provider.dart';

final astroServiceProvider = Provider<AstroService>((_) => AstroService());

// Synchronous natal chart — cached by Riverpod, recomputes only when profile changes.
final natalChartProvider = Provider<NatalChart?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;
  return AstroService().computeNatal(profile);
});

final astroResultProvider = FutureProvider<AstroResult?>((ref) async {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  final service = ref.read(astroServiceProvider);
  // Run in a separate isolate via compute isn't needed here since
  // sweph is fast (~50ms for 9 planets). Isolate adds complexity for no gain.
  return service.compute(profile);
});

// Toggle visibility of individual planets — stored as set of hidden planets
class PlanetFilterNotifier extends Notifier<Set<Planet>> {
  @override
  Set<Planet> build() => {};

  void toggle(Planet planet) {
    final s = Set<Planet>.from(state);
    if (s.contains(planet)) {
      s.remove(planet);
    } else {
      s.add(planet);
    }
    state = s;
  }

  bool isVisible(Planet planet) => !state.contains(planet);
}

final planetFilterProvider =
    NotifierProvider<PlanetFilterNotifier, Set<Planet>>(PlanetFilterNotifier.new);
