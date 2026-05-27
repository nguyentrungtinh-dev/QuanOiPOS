import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/workspace_context/data/datasources/workspace_remote_data_source.dart';
import 'package:quan_oi/features/workspace_context/data/models/store_model.dart';
import 'package:quan_oi/features/workspace_context/data/repositories/workspace_repository_impl.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';

void main() {
  group('StoreModel', () {
    test('maps stores payload from backend', () {
      final stores = StoreModel.listFromJson(_storesData);

      expect(stores, hasLength(4));

      final poseidon = stores.first;
      expect(poseidon.id, 2);
      expect(poseidon.ownerAccountId, 8);
      expect(poseidon.storeName, 'Buffet Poseidon Vincom Plaza Lê Văn Việt');
      expect(poseidon.phone, '0961813466');
      expect(poseidon.address, contains('Lê Văn Việt'));
      expect(poseidon.statusCode, 1);
      expect(poseidon.createdAt, isNotNull);
      expect(poseidon.updatedAt, isNotNull);
      expect(poseidon.isDeleted, isFalse);

      final entity = poseidon.toEntity();
      expect(entity.status, StoreStatus.active);
      expect(entity.status.label, 'Hoạt động');
      expect(entity.status.canAccess, isTrue);
    });

    test('maps empty store list', () {
      expect(StoreModel.listFromJson(null), isEmpty);
      expect(StoreModel.listFromJson(const []), isEmpty);
    });

    test('maps store status values and fallback', () {
      expect(StoreStatus.fromCode(1), StoreStatus.active);
      expect(StoreStatus.fromCode(2), StoreStatus.inactive);
      expect(StoreStatus.fromCode(3), StoreStatus.closed);
      expect(StoreStatus.fromCode(99), StoreStatus.unknown);
      expect(StoreStatus.fromCode(2).label, 'Ngưng hoạt động');
      expect(StoreStatus.fromCode(3).label, 'Đóng cửa');
      expect(StoreStatus.fromCode(99).label, 'Không xác định');
    });
  });

  group('WorkspaceRemoteDataSource', () {
    test('loads stores from /stores/my', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Lay danh sach Store cua tai khoan thanh cong',
                  'data': _storesData,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = WorkspaceRemoteDataSource(DioClient(dio));

      final stores = await dataSource.getMyStores();

      expect(requestedPath, '/stores/my');
      expect(stores, hasLength(4));
      expect(stores.first.storeName, contains('Poseidon'));
    });

    test('loads empty list when user has no stores', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Lay danh sach Store cua tai khoan thanh cong',
                  'data': <Object>[],
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = WorkspaceRemoteDataSource(DioClient(dio));

      final stores = await dataSource.getMyStores();

      expect(stores, isEmpty);
    });
  });

  group('WorkspaceRepositoryImpl', () {
    test('filters deleted stores and keeps all non-deleted statuses', () async {
      final repository = WorkspaceRepositoryImpl(
        _FakeWorkspaceRemoteDataSource(StoreModel.listFromJson(_storesData)),
      );

      final stores = await repository.loadMyStores();

      expect(stores, hasLength(3));
      expect(stores.map((store) => store.status), [
        StoreStatus.active,
        StoreStatus.inactive,
        StoreStatus.closed,
      ]);
    });
  });
}

class _FakeWorkspaceRemoteDataSource extends WorkspaceRemoteDataSource {
  final List<StoreModel> stores;

  _FakeWorkspaceRemoteDataSource(this.stores) : super(DioClient(Dio()));

  @override
  Future<List<StoreModel>> getMyStores() async {
    return stores;
  }
}

const _storesData = [
  {
    'id': 2,
    'ownerAccountId': 8,
    'storeName': 'Buffet Poseidon Vincom Plaza Lê Văn Việt',
    'phone': '0961813466',
    'address':
        'TTTM Vincom Plaza, 50 Đ. Lê Văn Việt, Tăng Nhơn Phú, Hồ Chí Minh',
    'status': 1,
    'createdAt': '2026-05-14T06:06:43.760278Z',
    'createdBy': null,
    'updatedAt': '2026-05-25T16:38:55.996903Z',
    'updatedBy': null,
    'isDeleted': false,
  },
  {
    'id': 5,
    'ownerAccountId': 8,
    'storeName': 'FPT Shipper Vip',
    'phone': '0123456789',
    'address': 'Gần Đại Học FPT',
    'status': 2,
    'createdAt': '2026-05-25T15:47:21.486841Z',
    'createdBy': null,
    'updatedAt': '2026-05-25T16:38:44.027537Z',
    'updatedBy': null,
    'isDeleted': false,
  },
  {
    'id': 6,
    'ownerAccountId': 8,
    'storeName': 'Kitchen Closed',
    'phone': '0123000000',
    'address': 'Quận 1',
    'status': 3,
    'createdAt': null,
    'createdBy': null,
    'updatedAt': null,
    'updatedBy': null,
    'isDeleted': false,
  },
  {
    'id': 7,
    'ownerAccountId': 8,
    'storeName': 'Deleted Store',
    'phone': '0123999999',
    'address': 'Quận 3',
    'status': 1,
    'createdAt': null,
    'createdBy': null,
    'updatedAt': null,
    'updatedBy': null,
    'isDeleted': true,
  },
];
