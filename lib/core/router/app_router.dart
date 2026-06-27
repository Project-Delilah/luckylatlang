import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/intro/intro_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/map/map_screen.dart';

final routerProvider = Provider<GoRouter>((_) {
  return GoRouter(
    initialLocation: Routes.intro,
    routes: [
      GoRoute(
        path: Routes.intro,
        builder: (ctx, state) => const IntroScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (ctx, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.map,
        builder: (ctx, state) => const MapScreen(),
      ),
    ],
  );
});

abstract final class Routes {
  static const intro = '/';
  static const profile = '/profile';
  static const map = '/map';
}
