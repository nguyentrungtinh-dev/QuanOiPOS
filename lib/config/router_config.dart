import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/index.dart';
import '../features/auth/domain/entities/account_type.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/system_admin/presentation/pages/system_admin_home_page.dart';
import '../features/store_operations/presentation/pages/about_app_page.dart';
import '../features/store_operations/presentation/pages/operation_regulations_page.dart';
import '../features/store_operations/presentation/pages/privacy_policy_page.dart';
import '../features/store_operations/presentation/pages/store_home_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_check_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_import_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_ledger_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_management_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_stock_page.dart';
import '../features/store_operations/presentation/pages/store_overview_page.dart';
import '../features/store_operations/table_management/presentation/pages/table_management_page.dart';
import '../features/store_operations/table_management/presentation/pages/table_settings_page.dart';
import '../features/subscription/presentation/pages/store_subscription_page.dart';
import '../features/workspace_context/presentation/controllers/last_active_store_state.dart';
import '../features/workspace_context/presentation/pages/my_stores_page.dart';
import '../features/workspace_context/presentation/providers/workspace_context_providers.dart';

/// Route names as constants
abstract final class RouteNames {
  static const String auth = 'auth';
  static const String systemAdminHome = 'system-admin-home';
  static const String storeHome = 'store-home';
  static const String storeOverview = 'store-overview';
  static const String storeInventoryManagement = 'store-inventory-management';
  static const String storeInventoryCheck = 'store-inventory-check';
  static const String storeInventoryImport = 'store-inventory-import';
  static const String storeInventoryLedger = 'store-inventory-ledger';
  static const String storeInventoryStock = 'store-inventory-stock';
  static const String storeTableManagement = 'store-table-management';
  static const String storeTableSettings = 'store-table-settings';
  static const String myStores = 'my-stores';
  static const String storeSubscription = 'store-subscription';
  static const String operationRegulations = 'operation-regulations';
  static const String privacyPolicy = 'privacy-policy';
  static const String aboutApp = 'about-app';
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
        builder: (context, state) => const _BootstrapSplashPage(),
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
        path: '/stores/:storeId/inventory',
        name: RouteNames.storeInventoryManagement,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryManagementPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/inventory/stock',
        name: RouteNames.storeInventoryStock,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryStockPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/inventory/checks',
        name: RouteNames.storeInventoryCheck,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryCheckPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/inventory/imports',
        name: RouteNames.storeInventoryImport,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryImportPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/inventory/ledger',
        name: RouteNames.storeInventoryLedger,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryLedgerPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/tables/settings',
        name: RouteNames.storeTableSettings,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return TableSettingsPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/tables',
        name: RouteNames.storeTableManagement,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return TableManagementPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId',
        name: RouteNames.storeOverview,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreOverviewPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/store-subscription',
        name: RouteNames.storeSubscription,
        builder: (context, state) => const StoreSubscriptionPage(),
      ),
      GoRoute(
        path: '/operation-regulations',
        name: RouteNames.operationRegulations,
        builder: (context, state) => const OperationRegulationsPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: RouteNames.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/about-app',
        name: RouteNames.aboutApp,
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: '/my-stores',
        name: RouteNames.myStores,
        builder: (context, state) => const MyStoresPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final lastActiveStoreState = ref.read(lastActiveStoreNotifierProvider);

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
            : _storeUserLanding(lastActiveStoreState);
      }

      // If unauthenticated, force to auth unless already there
      if (!authState.isAuthenticated) {
        return state.matchedLocation == '/auth' ? null : '/auth';
      }

      // If authenticated, prevent going back to /auth
      if (state.matchedLocation == '/auth') {
        return authState.accountType == AccountType.systemAdmin
            ? '/system-admin-home'
            : _storeUserLanding(lastActiveStoreState, fromAuthRoute: true);
      }

      // Cross-account type route check
      if (authState.accountType == AccountType.systemAdmin) {
        if (state.matchedLocation == '/store-home' ||
            state.matchedLocation == '/store-subscription' ||
            state.matchedLocation == '/operation-regulations' ||
            state.matchedLocation == '/privacy-policy' ||
            state.matchedLocation == '/about-app' ||
            state.matchedLocation == '/my-stores' ||
            state.matchedLocation.startsWith('/stores/')) {
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
    if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      unawaited(ref.read(lastActiveStoreNotifierProvider.notifier).clear());
    }
    router.refresh();
  });

  ref.listen(lastActiveStoreNotifierProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);
  return router;
});

String? _storeUserLanding(
  LastActiveStoreState lastActiveStoreState, {
  bool fromAuthRoute = false,
}) {
  if (lastActiveStoreState.isBootstrapping) {
    return fromAuthRoute ? '/' : null;
  }

  final lastStoreId = lastActiveStoreState.lastStoreId;
  if (lastStoreId != null) {
    return '/stores/$lastStoreId';
  }

  return '/store-home';
}

class _BootstrapSplashPage extends StatelessWidget {
  const _BootstrapSplashPage();

  static const _splashAsset = 'assets/images/splash_screen.png';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Image(image: AssetImage(_splashAsset), fit: BoxFit.cover),
      ),
    );
  }
}
