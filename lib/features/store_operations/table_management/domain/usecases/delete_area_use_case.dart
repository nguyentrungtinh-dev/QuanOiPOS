import '../repositories/table_management_repository.dart';

class DeleteAreaUseCase {
  final TableManagementRepository _repository;

  const DeleteAreaUseCase(this._repository);

  Future<void> call(int areaId) {
    return _repository.deleteArea(areaId);
  }
}
