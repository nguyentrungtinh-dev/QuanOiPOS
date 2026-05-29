import '../entities/area.dart';
import '../repositories/table_management_repository.dart';

class UpdateAreaUseCase {
  final TableManagementRepository _repository;

  const UpdateAreaUseCase(this._repository);

  Future<Area> call({
    required int areaId,
    required String name,
    required String description,
  }) {
    return _repository.updateArea(
      areaId: areaId,
      name: name,
      description: description,
    );
  }
}
