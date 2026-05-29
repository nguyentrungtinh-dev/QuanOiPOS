import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/table_management/data/models/area_model.dart';
import 'package:quan_oi/features/store_operations/table_management/data/models/area_request_models.dart';
import 'package:quan_oi/features/store_operations/table_management/data/models/dining_table_model.dart';
import 'package:quan_oi/features/store_operations/table_management/data/models/table_area_group_model.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_status.dart';

void main() {
  group('AreaModel', () {
    test('parses area list response data', () {
      final areas = AreaModel.listFromJson([
        {
          'id': 6,
          'storeId': 5,
          'name': 'Bên trong',
          'description': 'Tầng 1',
          'displayOrder': 1,
          'isActive': true,
          'createdAt': '2026-05-29T04:01:41.259Z',
          'createdBy': 'owner',
          'updatedAt': null,
          'updatedBy': null,
          'isDeleted': false,
        },
      ]);

      expect(areas, hasLength(1));
      expect(areas.single.id, 6);
      expect(areas.single.name, 'Bên trong');
      expect(areas.single.toEntity().isDeleted, isFalse);
    });

    test('returns empty list for null payload', () {
      expect(AreaModel.listFromJson(null), isEmpty);
    });

    test('parses create and update area response data', () {
      final area = AreaModel.fromJson({
        'id': 9,
        'storeId': 5,
        'name': 'phòng vip',
        'description': 'Đây là phòng vip',
        'displayOrder': 4,
        'isActive': true,
        'createdAt': '2026-05-29T05:37:43.018974Z',
        'createdBy': null,
        'updatedAt': '2026-05-29T05:40:18.025412Z',
        'updatedBy': null,
        'isDeleted': false,
      });

      expect(area.id, 9);
      expect(area.name, 'phòng vip');
      expect(area.displayOrder, 4);
      expect(area.updatedAt, isNotNull);
    });
  });

  group('Area request models', () {
    test('serializes create/update/display order payloads', () {
      expect(
        const CreateAreaRequestModel(
          storeId: 5,
          name: 'vip',
          description: 'đây là phòng vip',
        ).toJson(),
        {'storeId': 5, 'name': 'vip', 'description': 'đây là phòng vip'},
      );
      expect(
        const UpdateAreaRequestModel(
          name: 'phòng vip',
          description: 'Đây là phòng vip',
        ).toJson(),
        {'name': 'phòng vip', 'description': 'Đây là phòng vip'},
      );
      expect(
        const UpdateAreaDisplayOrderRequestModel(displayOrder: 1).toJson(),
        {'displayOrder': 1},
      );
    });
  });

  group('DiningTableModel', () {
    test('maps known and unknown statuses', () {
      expect(
        DiningTableModel.statusFromJson('Available'),
        TableStatus.available,
      );
      expect(DiningTableModel.statusFromJson('Occupied'), TableStatus.occupied);
      expect(DiningTableModel.statusFromJson('Reserved'), TableStatus.reserved);
      expect(DiningTableModel.statusFromJson('Cleaning'), TableStatus.unknown);
    });
  });

  group('TableAreaGroupModel', () {
    test('parses area with tables', () {
      final groups = TableAreaGroupModel.listFromJson([
        {
          'id': 6,
          'storeId': 5,
          'name': 'Bên trong',
          'description': 'string',
          'displayOrder': 1,
          'isActive': true,
          'tables': [
            {
              'id': 3,
              'storeId': 5,
              'areaId': 6,
              'name': 'Bàn 1',
              'capacity': 4,
              'status': 'Available',
              'createdAt': '2026-05-29T02:18:52.976458Z',
              'createdBy': null,
              'updatedAt': null,
              'updatedBy': null,
              'isDeleted': false,
            },
          ],
        },
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.area.name, 'Bên trong');
      expect(groups.single.tables.single.status, TableStatus.available);
    });
  });
}
