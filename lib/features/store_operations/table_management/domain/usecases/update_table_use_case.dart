import '../entities/dining_table.dart';
import '../repositories/table_management_repository.dart';

class UpdateTableUseCase {
  final TableManagementRepository _repository;

  const UpdateTableUseCase(this._repository);

  Future<DiningTable> call({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  }) {
    return _repository.updateTable(
      tableId: tableId,
      areaId: areaId,
      name: name,
      capacity: capacity,
    );
  }
}
