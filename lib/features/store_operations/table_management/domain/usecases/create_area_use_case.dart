import '../entities/area.dart';
import '../repositories/table_management_repository.dart';

class CreateAreaUseCase {
  final TableManagementRepository _repository;

  const CreateAreaUseCase(this._repository);

  Future<Area> call({
    required int storeId,
    required String name,
    required String description,
  }) {
    return _repository.createArea(
      storeId: storeId,
      name: name,
      description: description,
    );
  }
}
