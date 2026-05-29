import '../entities/area.dart';
import '../repositories/table_management_repository.dart';

class UpdateAreaDisplayOrderUseCase {
  final TableManagementRepository _repository;

  const UpdateAreaDisplayOrderUseCase(this._repository);

  Future<Area> call({required int areaId, required int displayOrder}) {
    return _repository.updateAreaDisplayOrder(
      areaId: areaId,
      displayOrder: displayOrder,
    );
  }
}
