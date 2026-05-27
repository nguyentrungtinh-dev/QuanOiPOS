import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workspace_context_providers.dart';
import 'my_stores_state.dart';

class MyStoresNotifier extends AutoDisposeNotifier<MyStoresState> {
  bool _initialLoadStarted = false;

  @override
  MyStoresState build() {
    Future.microtask(loadStores);
    return const MyStoresState.initial();
  }

  Future<void> loadStores() async {
    if (_initialLoadStarted && state.status == MyStoresStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    state = state.copyWith(status: MyStoresStatus.loading, clearError: true);

    try {
      final loadMyStoresUseCase = ref.read(loadMyStoresUseCaseProvider);
      final stores = await loadMyStoresUseCase();
      state = state.copyWith(
        status: MyStoresStatus.ready,
        stores: stores,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MyStoresStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
