import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/constants/app_constants.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('StoreUser opens operation regulations from account hub', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/store-home');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Quy chế hoạt động'), findsOneWidget);

    await tester.tap(find.text('Quy chế hoạt động'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Quy chế hoạt động'), findsOneWidget);
    expect(
      find.byKey(const Key('operation_regulations_pdf_viewer')),
      findsOneWidget,
    );
  });

  testWidgets('StoreUser opens privacy policy from account hub', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/store-home');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Chính sách bảo mật'), findsOneWidget);

    await tester.tap(find.text('Chính sách bảo mật'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.byKey(const Key('privacy_policy_pdf_viewer')), findsOneWidget);
  });

  testWidgets('StoreUser opens about app from account hub', (tester) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/store-home');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Về ứng dụng'), findsOneWidget);
    expect(find.text('Đóng góp ý kiến'), findsOneWidget);

    await tester.ensureVisible(find.text('Về ứng dụng'));
    await tester.tap(find.text('Về ứng dụng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Về ứng dụng'), findsOneWidget);
    expect(find.byKey(const Key('about_app_header_card')), findsOneWidget);
    expect(find.byKey(const Key('about_app_logo')), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(
      find.text('Phiên bản ứng dụng ${AppConstants.appVersion}'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('about_app_content_card')), findsOneWidget);
    expect(find.text('QUÁN ƠI'), findsOneWidget);
    expect(
      find.textContaining('QUẢN LÝ BÁN HÀNG CHỈ BẰNG MỘT CHIẾC ĐIỆN THOẠI'),
      findsWidgets,
    );
  });

  testWidgets(
    'SystemAdmin is redirected away from operation regulations route',
    (tester) async {
      final container = _buildContainer(AccountType.systemAdmin);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/operation-regulations');
      await tester.pumpAndSettle();

      expect(find.text('SystemAdmin Workspace'), findsOneWidget);
      expect(
        find.byKey(const Key('operation_regulations_pdf_viewer')),
        findsNothing,
      );
    },
  );

  testWidgets('SystemAdmin is redirected away from privacy policy route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/privacy-policy');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.byKey(const Key('privacy_policy_pdf_viewer')), findsNothing);
  });

  testWidgets('SystemAdmin is redirected away from about app route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/about-app');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.byKey(const Key('about_app_content_card')), findsNothing);
  });
}

ProviderContainer _buildContainer(AccountType accountType) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          AuthState(
            status: AuthStatus.authenticated,
            accountType: accountType,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
    ],
  );
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
}

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}
