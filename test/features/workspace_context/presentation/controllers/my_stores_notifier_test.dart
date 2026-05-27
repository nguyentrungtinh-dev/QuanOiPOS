import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/controllers/my_stores_state.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  test('my stores notifier loads stores on provider creation', () async {
    final repository = _FakeWorkspaceRepository();
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    expect(
      container.read(myStoresNotifierProvider).status,
      MyStoresStatus.initial,
    );

    await _flushMicrotasks();

    final state = container.read(myStoresNotifierProvider);
    expect(state.status, MyStoresStatus.ready);
    expect(state.stores, hasLength(3));
    expect(state.errorMessage, isNull);
  });

  test('my stores notifier supports empty store list', () async {
    final repository = _FakeWorkspaceRepository(stores: const []);
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(myStoresNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(myStoresNotifierProvider);
    expect(state.status, MyStoresStatus.ready);
    expect(state.stores, isEmpty);
  });

  test('my stores notifier exposes error when load fails', () async {
    final repository = _FakeWorkspaceRepository(
      loadError: Exception('Network down'),
    );
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(myStoresNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(myStoresNotifierProvider);
    expect(state.status, MyStoresStatus.error);
    expect(state.errorMessage, 'Network down');
  });

  test('my stores notifier filters by name phone and address', () async {
    final repository = _FakeWorkspaceRepository();
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(myStoresNotifierProvider);
    await _flushMicrotasks();

    final notifier = container.read(myStoresNotifierProvider.notifier);

    notifier.updateSearchQuery('poseidon');
    expect(
      container.read(myStoresNotifierProvider).filteredStores.single.storeName,
      contains('Poseidon'),
    );

    notifier.updateSearchQuery('0123456789');
    expect(
      container.read(myStoresNotifierProvider).filteredStores.single.storeName,
      'FPT Shipper Vip',
    );

    notifier.updateSearchQuery('quận 1');
    expect(
      container.read(myStoresNotifierProvider).filteredStores.single.storeName,
      'Kitchen Closed',
    );

    notifier.updateSearchQuery('khong-co');
    expect(container.read(myStoresNotifierProvider).filteredStores, isEmpty);
  });
}

ProviderContainer _containerWithRepository(
  _FakeWorkspaceRepository repository,
) {
  return ProviderContainer(
    overrides: [
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
    ],
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderSubscription<MyStoresState> _listen(ProviderContainer container) {
  return container.listen<MyStoresState>(
    myStoresNotifierProvider,
    (previous, next) {},
  );
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Exception? loadError;
  final List<Store> stores;

  const _FakeWorkspaceRepository({
    this.loadError,
    this.stores = _defaultStores,
  });

  @override
  Future<List<Store>> loadMyStores() async {
    final error = loadError;
    if (error != null) {
      throw error;
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
