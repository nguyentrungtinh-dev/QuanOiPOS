import '../entities/area.dart';
import '../entities/dining_table.dart';
import '../entities/table_area_group.dart';

abstract class TableManagementRepository {
  Future<List<Area>> loadAreas(int storeId);

  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  });

  Future<Area> createArea({
    required int storeId,
    required String name,
    required String description,
  });

  Future<DiningTable> createTable({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  });

  Future<DiningTable> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  });

  Future<Area> updateArea({
    required int areaId,
    required String name,
    required String description,
  });

  Future<Area> updateAreaDisplayOrder({
    required int areaId,
    required int displayOrder,
  });

  Future<void> deleteArea(int areaId);
}
