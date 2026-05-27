import '../../domain/entities/store.dart';

enum MyStoresStatus { initial, loading, ready, error }

class MyStoresState {
  final MyStoresStatus status;
  final List<Store> stores;
  final String searchQuery;
  final String? errorMessage;

  const MyStoresState({
    required this.status,
    this.stores = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  const MyStoresState.initial()
    : status = MyStoresStatus.initial,
      stores = const [],
      searchQuery = '',
      errorMessage = null;

  bool get isLoading => status == MyStoresStatus.loading;

  List<Store> get filteredStores {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return stores;
    }

    return stores.where((store) {
      return store.storeName.toLowerCase().contains(query) ||
          store.phone.toLowerCase().contains(query) ||
          store.address.toLowerCase().contains(query);
    }).toList();
  }

  MyStoresState copyWith({
    MyStoresStatus? status,
    List<Store>? stores,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyStoresState(
      status: status ?? this.status,
      stores: stores ?? this.stores,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
