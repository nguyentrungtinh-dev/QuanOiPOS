import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/index.dart';
import '../features/auth/domain/entities/account_type.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/system_admin/presentation/pages/system_admin_home_page.dart';
import '../features/store_operations/presentation/pages/about_app_page.dart';
import '../features/store_operations/presentation/pages/app_settings_page.dart';
import '../features/store_operations/presentation/pages/operation_regulations_page.dart';
import '../features/store_operations/presentation/pages/privacy_policy_page.dart';
import '../features/store_operations/presentation/pages/store_home_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_check_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_import_ingredients_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_import_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_import_products_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_ledger_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_management_page.dart';
import '../features/store_operations/presentation/pages/store_inventory_stock_page.dart';
import '../features/store_operations/presentation/pages/store_overview_page.dart';
import '../features/store_operations/staff_management/presentation/pages/invite_staff_page.dart';
import '../features/store_operations/staff_management/presentation/pages/staff_detail_page.dart';
import '../features/store_operations/staff_management/presentation/pages/staff_management_page.dart';
import '../features/store_operations/staff_management/presentation/pages/staff_role_form_page.dart';
import '../features/store_operations/table_management/presentation/pages/table_management_page.dart';
import '../features/store_operations/table_management/presentation/pages/table_settings_page.dart';
import '../features/subscription/presentation/pages/store_subscription_page.dart';
import '../features/subscription/presentation/pages/subscription_checkout_page.dart';
import '../features/workspace_context/presentation/controllers/last_active_store_state.dart';
import '../features/workspace_context/presentation/pages/create_store_page.dart';
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
  static const String storeInventoryImportIngredients =
      'store-inventory-import-ingredients';
  static const String storeInventoryImportProducts =
      'store-inventory-import-products';
  static const String storeInventoryLedger = 'store-inventory-ledger';
  static const String storeInventoryStock = 'store-inventory-stock';
  static const String storeTableManagement = 'store-table-management';
  static const String storeTableSettings = 'store-table-settings';
  static const String storeStaffManagement = 'store-staff-management';
  static const String storeStaffUserDetail = 'store-staff-user-detail';
  static const String storeStaffInvitationDetail =
      'store-staff-invitation-detail';
  static const String storeStaffInvite = 'store-staff-invite';
  static const String storeStaffRoleCreate = 'store-staff-role-create';
  static const String storeStaffRoleDetail = 'store-staff-role-detail';
  static const String myStores = 'my-stores';
  static const String createStore = 'create-store';
  static const String storeSubscription = 'store-subscription';
  static const String subscriptionCheckout = 'subscription-checkout';
  static const String appSettings = 'app-settings';
  static const String operationRegulations = 'operation-regulations';
  static const String privacyPolicy = 'privacy-policy';
  static const String aboutApp = 'about-app';
  static const String changePassword = 'change-password';
  static const String profile = 'profile';
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
        path: '/stores/:storeId/inventory/imports/products',
        name: RouteNames.storeInventoryImportProducts,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryImportProductsPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/inventory/imports/ingredients',
        name: RouteNames.storeInventoryImportIngredients,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StoreInventoryImportIngredientsPage(storeId: storeId);
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
        path: '/stores/:storeId/staff/users/:storeUserId',
        name: RouteNames.storeStaffUserDetail,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');
          final storeUserId = int.tryParse(
            state.pathParameters['storeUserId'] ?? '',
          );

          if (storeId == null || storeUserId == null) {
            return const Scaffold(
              body: Center(child: Text('Nhân viên không hợp lệ')),
            );
          }

          return StaffDetailPage(storeId: storeId, storeUserId: storeUserId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/staff/invitations/:invitationId',
        name: RouteNames.storeStaffInvitationDetail,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');
          final invitationId = int.tryParse(
            state.pathParameters['invitationId'] ?? '',
          );

          if (storeId == null || invitationId == null) {
            return const Scaffold(
              body: Center(child: Text('Lời mời không hợp lệ')),
            );
          }

          return StaffDetailPage(storeId: storeId, invitationId: invitationId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/staff/invite',
        name: RouteNames.storeStaffInvite,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return InviteStaffPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/staff/roles/new',
        name: RouteNames.storeStaffRoleCreate,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StaffRoleFormPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/staff/roles/:roleId',
        name: RouteNames.storeStaffRoleDetail,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');
          final roleId = int.tryParse(state.pathParameters['roleId'] ?? '');

          if (storeId == null || roleId == null) {
            return const Scaffold(
              body: Center(child: Text('Vai trò không hợp lệ')),
            );
          }

          return StaffRoleFormPage(storeId: storeId, roleId: roleId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/staff',
        name: RouteNames.storeStaffManagement,
        builder: (context, state) {
          final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');

          if (storeId == null) {
            return const Scaffold(
              body: Center(child: Text('Cửa hàng không hợp lệ')),
            );
          }

          return StaffManagementPage(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/create',
        name: RouteNames.createStore,
        builder: (context, state) => const CreateStorePage(),
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
        path: '/subscription-checkout',
        name: RouteNames.subscriptionCheckout,
        builder: (context, state) {
          final paymentLink = state.extra;
          if (paymentLink is! String || paymentLink.trim().isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Link thanh toán không hợp lệ')),
            );
          }

          return SubscriptionCheckoutPage(paymentLink: paymentLink);
        },
      ),
      GoRoute(
        path: '/app-settings',
        name: RouteNames.appSettings,
        builder: (context, state) => const AppSettingsPage(),
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
        path: '/change-password',
        name: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
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
            state.matchedLocation == '/subscription-checkout' ||
            state.matchedLocation == '/app-settings' ||
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
