import '../../domain/entities/store.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;

  const WorkspaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Store>> loadMyStores() async {
    final stores = await _remoteDataSource.getMyStores();
    return stores
        .where((store) => !store.isDeleted)
        .map((store) => store.toEntity())
        .toList();
  }
}
