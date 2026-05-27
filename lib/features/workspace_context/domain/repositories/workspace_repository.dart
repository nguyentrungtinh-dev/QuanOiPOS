import '../entities/store.dart';

abstract class WorkspaceRepository {
  Future<List<Store>> loadMyStores();
}
