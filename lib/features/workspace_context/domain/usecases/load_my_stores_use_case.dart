import '../entities/store.dart';
import '../repositories/workspace_repository.dart';

class LoadMyStoresUseCase {
  final WorkspaceRepository _repository;

  const LoadMyStoresUseCase(this._repository);

  Future<List<Store>> call() {
    return _repository.loadMyStores();
  }
}
