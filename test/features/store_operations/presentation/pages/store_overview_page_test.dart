import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_overview_page.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('store overview renders dashboard and active overview nav', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [
          StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
          StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
          StorePermission(permissionId: 4, code: 'INVENTORY.VIEW'),
          StorePermission(permissionId: 5, code: 'AREA.VIEW'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FPT Shipper Vip'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(
      find.text('Bạn chưa tạo hóa đơn để phân tích lãi lỗ'),
      findsOneWidget,
    );
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
    expect(find.text('Quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsNothing);
  });

  testWidgets('store overview blocks dashboard without DASHBOARD.VIEW', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 2, code: 'STORE.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem tổng quan'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('store overview disables missing permission actions', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
    expect(find.text('Bạn chưa có quyền cập nhật cửa hàng'), findsWidgets);
  });

  testWidgets('store overview enables inventory without INVENTORY.VIEW', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý kho'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý kho'), findsNothing);
  });

  testWidgets(
    'inventory tile navigates to mock stock page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
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

      router.go('/stores/5');
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quản lý kho'));
      await tester.pumpAndSettle();

      expect(find.text('Quản lý kho'), findsOneWidget);
      expect(find.text('Nhập kho'), findsOneWidget);
      expect(find.text('Xuất kho'), findsOneWidget);
      expect(find.text('Sổ kho'), findsOneWidget);
      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Tồn kho'), findsOneWidget);
      expect(find.text('In mã vạch'), findsOneWidget);

      await tester.tap(find.text('Tồn kho'));
      await tester.pumpAndSettle();

      expect(find.text('Tồn kho'), findsOneWidget);
      expect(find.text('Tìm tên, mã SKU, ...'), findsOneWidget);
      expect(find.text('Danh mục'), findsWidgets);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Sắp xếp'), findsOneWidget);
      expect(
        find.textContaining('Số lượng 158', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Giá trị tồn 84.000', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Thăng Long'), findsOneWidget);
      expect(find.text('SP0048'), findsOneWidget);
      expect(find.text('Kho: 9/9'), findsOneWidget);
    },
  );

  testWidgets(
    'inventory import tile navigates to mock import page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
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

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhập kho'));
      await tester.pumpAndSettle();

      expect(find.text('Sổ nhập hàng'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ xác nhận'), findsOneWidget);
      expect(find.text('Chưa thanh toán'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsWidgets);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('#NH265'), findsOneWidget);
      expect(find.text('13:01 27/05/26'), findsOneWidget);
      expect(find.text('3.500'), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsWidgets);
      expect(find.text('Tạo nhập hàng'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'inventory ledger tile navigates to mock ledger page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
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

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sổ kho'));
      await tester.pumpAndSettle();

      expect(find.text('Sổ kho'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Loại hàng'), findsOneWidget);
      expect(find.text('Tồn đầu kỳ'), findsOneWidget);
      expect(find.text('106.000 đ'), findsOneWidget);
      expect(find.text('Nhập trong kỳ'), findsOneWidget);
      expect(find.text('87.500 đ'), findsOneWidget);
      expect(find.text('Xuất trong kỳ'), findsOneWidget);
      expect(find.text('59.500 đ'), findsOneWidget);
      expect(find.text('Tồn cuối kỳ'), findsOneWidget);
      expect(find.text('134.000 đ'), findsOneWidget);
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('Thăng Long'), findsWidgets);
      expect(find.text('SP0048'), findsWidgets);
      expect(find.text('#XH2074 - Bán hàng'), findsOneWidget);
      expect(find.text('SL: -1'), findsWidgets);
      expect(find.text('Xuất hàng'), findsOneWidget);
      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Nhập hàng'), findsOneWidget);
    },
  );

  testWidgets('inventory ledger page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/ledger');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('106.000 đ'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('inventory import page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/imports');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('#NH265'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'inventory check tile navigates to mock empty page without permission',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
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

      router.go('/stores/5/inventory');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiểm kho'));
      await tester.pumpAndSettle();

      expect(find.text('Kiểm kho'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đang kiểm kho'), findsOneWidget);
      expect(find.text('Đã cân bằng'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Nhân viên'), findsOneWidget);
      expect(find.text('Bạn chưa có phiếu kiểm kho nào!'), findsOneWidget);
      expect(find.text('Tạo kiểm kho'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    },
  );

  testWidgets('inventory check page keeps access error state', (tester) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/checks');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Bạn chưa có phiếu kiểm kho nào!'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('stock page keeps access error state instead of mock content', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [],
      accessError: Exception('Store access failed'),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5/inventory/stock');
    await tester.pumpAndSettle();

    expect(find.text('Store access failed'), findsOneWidget);
    expect(find.text('Thăng Long'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('store header opens switcher bottom sheet with active store', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_5')), findsOneWidget);
    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('store_switcher_search_field')),
      'poseidon',
    );
    await tester.pumpAndSettle();

    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_5')), findsNothing);
  });

  testWidgets('selecting current store closes switcher without route reload', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_5')));
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsNothing);
    expect(find.text('FPT Shipper Vip'), findsOneWidget);
  });

  testWidgets(
    'selecting another active store navigates to that store overview',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
      final container = _buildRouterContainer(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
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

      router.go('/stores/5');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('store_workspace_header_store_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch_store_2')));
      await tester.pumpAndSettle();

      expect(find.text('Buffet Poseidon'), findsOneWidget);
      expect(find.text('FPT Shipper Vip'), findsNothing);
      expect(lastActiveStoreStorage.lastStoreId, 2);
    },
  );

  testWidgets('store header account icon navigates back to account hub', (
    tester,
  ) async {
    final repository = const _FakeWorkspaceRepository(
      permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Xin chào, Test User'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('store load error offers navigation back to my stores', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository(
      permissions: const [
        StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
      ],
      accessError: Exception(
        'Tai khoan nguoi dung khong du quyen de thuc hien yeu cau nay!',
      ),
    );
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/5');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tai khoan nguoi dung khong du quyen de thuc hien yeu cau nay!',
      ),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Về danh sách cửa hàng'), findsOneWidget);

    await tester.tap(find.text('Về danh sách cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Danh sách cửa hàng'), findsOneWidget);
    expect(find.text('FPT Shipper Vip'), findsOneWidget);
  });

  testWidgets('inactive store is disabled in switcher', (tester) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_6')));
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_6')), findsOneWidget);
  });
}

Future<void> _pumpOverview(
  WidgetTester tester,
  _FakeWorkspaceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(repository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const StoreOverviewPage(storeId: 5),
      ),
    ),
  );
}

ProviderContainer _buildRouterContainer(
  _FakeWorkspaceRepository repository, {
  _FakeLastActiveStoreStorage? lastActiveStoreStorage,
}) {
  final storeStorage = lastActiveStoreStorage ?? _FakeLastActiveStoreStorage();

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            accountType: AccountType.storeUser,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
      ..._lastActiveStoreOverrides(storeStorage),
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

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<StorePermission> permissions;
  final Exception? accessError;

  const _FakeWorkspaceRepository({required this.permissions, this.accessError});

  @override
  Future<List<Store>> loadMyStores() async {
    return _stores;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _stores.firstWhere((store) => store.id == storeId);
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return permissions;
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    final error = accessError;
    if (error != null) {
      throw error;
    }

    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
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

const _stores = [
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza',
    status: StoreStatus.active,
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
