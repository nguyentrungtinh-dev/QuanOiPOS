import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/pages/my_stores_page.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('StoreUser can open my stores route from account menu', (
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

    await tester.tap(find.text('Cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Danh sách cửa hàng'), findsOneWidget);
    expect(
      find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
      findsOneWidget,
    );
    expect(find.text('Hoạt động'), findsOneWidget);
  });

  testWidgets('SystemAdmin is redirected away from my stores route', (
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

    router.go('/my-stores');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.text('Danh sách cửa hàng'), findsNothing);
  });

  testWidgets('my stores page enables access only for active stores', (
    tester,
  ) async {
    await _pumpMyStoresPage(tester, _FakeWorkspaceRepository());
    await tester.pumpAndSettle();

    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Ngưng hoạt động'), findsOneWidget);
    expect(find.text('Đóng cửa'), findsOneWidget);

    final activeButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_2')),
    );
    final inactiveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_5')),
    );
    final closedButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_6')),
    );

    expect(activeButton.onPressed, isNotNull);
    expect(inactiveButton.onPressed, isNull);
    expect(closedButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('access_store_2')));
    await tester.pump();

    expect(
      find.text('Truy cập cửa hàng sẽ được triển khai sau'),
      findsOneWidget,
    );
  });

  testWidgets('my stores page shows empty and search-empty states', (
    tester,
  ) async {
    await _pumpMyStoresPage(tester, const _FakeWorkspaceRepository(stores: []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có cửa hàng'), findsOneWidget);

    await _pumpMyStoresPage(tester, _FakeWorkspaceRepository());
    await tester.pumpAndSettle();

    expect(
      find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('my_stores_search_field')),
      'khong-co',
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy cửa hàng'), findsOneWidget);
  });

  testWidgets('my stores page shows loading state', (tester) async {
    final completer = Completer<List<Store>>();
    await _pumpMyStoresPage(
      tester,
      _FakeWorkspaceRepository(loadCompleter: completer),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('my stores page shows error state', (tester) async {
    await _pumpMyStoresPage(
      tester,
      _FakeWorkspaceRepository(loadError: Exception('Network down')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Network down'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}

Future<void> _pumpMyStoresPage(
  WidgetTester tester,
  _FakeWorkspaceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const MyStoresPage()),
    ),
  );
}

ProviderContainer _buildContainer(
  AccountType accountType, {
  List<Store> stores = _defaultStores,
}) {
  final repository = _FakeWorkspaceRepository(stores: stores);

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
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
    ],
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Exception? loadError;
  final Completer<List<Store>>? loadCompleter;
  final List<Store> stores;

  const _FakeWorkspaceRepository({
    this.loadError,
    this.loadCompleter,
    this.stores = _defaultStores,
  });

  @override
  Future<List<Store>> loadMyStores() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }

    final completer = loadCompleter;
    if (completer != null) {
      return completer.future;
    }

    return stores;
  }
}

const _defaultStores = [
  Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon Vincom Plaza Lê Văn Việt',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza, 50 Đ. Lê Văn Việt',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.inactive,
    isDeleted: false,
  ),
  Store(
    id: 6,
    ownerAccountId: 8,
    storeName: 'Kitchen Closed',
    phone: '0900000000',
    address: 'Quận 1',
    status: StoreStatus.closed,
    isDeleted: false,
  ),
];
