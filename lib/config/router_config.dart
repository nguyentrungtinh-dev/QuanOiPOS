import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/account_type.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/system_admin/presentation/pages/system_admin_home_page.dart';
import '../features/store_operations/presentation/pages/store_home_page.dart';
import '../features/subscription/presentation/pages/store_subscription_page.dart';
import '../features/workspace_context/presentation/pages/my_stores_page.dart';

/// Route names as constants
abstract final class RouteNames {
  static const String auth = 'auth';
  static const String systemAdminHome = 'system-admin-home';
  static const String storeHome = 'store-home';
  static const String myStores = 'my-stores';
  static const String storeSubscription = 'store-subscription';
  static const String splash = 'splash';
}

/// Centralized router configuration with auth guard
final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  router = GoRouter(
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) {
          // Temporary splash while bootstrapping
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: '/auth',
        name: RouteNames.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/system-admin-home',
        name: RouteNames.systemAdminHome,
        builder: (context, state) => const SystemAdminHomePage(),
      ),
      GoRoute(
        path: '/store-home',
        name: RouteNames.storeHome,
        builder: (context, state) => const StoreHomePage(),
      ),
      GoRoute(
        path: '/store-subscription',
        name: RouteNames.storeSubscription,
        builder: (context, state) => const StoreSubscriptionPage(),
      ),
      GoRoute(
        path: '/my-stores',
        name: RouteNames.myStores,
        builder: (context, state) => const MyStoresPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);

      // While bootstrapping, show splash
      if (authState.isBootstrapping) {
        return state.matchedLocation == '/' ? null : '/';
      }

      // Once bootstrap finishes, root should resolve to a real route
      if (state.matchedLocation == '/') {
        if (!authState.isAuthenticated) {
          return '/auth';
        }

        return authState.accountType == AccountType.systemAdmin
            ? '/system-admin-home'
            : '/store-home';
      }

      // If unauthenticated, force to auth unless already there
      if (!authState.isAuthenticated) {
        return state.matchedLocation == '/auth' ? null : '/auth';
      }

      // If authenticated, prevent going back to /auth
      if (state.matchedLocation == '/auth') {
        return authState.accountType == AccountType.systemAdmin
            ? '/system-admin-home'
            : '/store-home';
      }

      // Cross-account type route check
      if (authState.accountType == AccountType.systemAdmin) {
        if (state.matchedLocation == '/store-home' ||
            state.matchedLocation == '/store-subscription' ||
            state.matchedLocation == '/my-stores') {
          return '/system-admin-home';
        }
      } else if (authState.accountType == AccountType.storeUser) {
        if (state.matchedLocation == '/system-admin-home') {
          return '/store-home';
        }
      }

      // Allow the route
      return null;
    },
  );

  ref.listen(authNotifierProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);
  return router;
});
