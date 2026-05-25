import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'package:quan_oi/features/subscription/data/models/service_package_model.dart';

void main() {
  group('ServicePackageModel', () {
    test('maps subscription plans payload from backend', () {
      final packages = ServicePackageModel.listFromJson(_subscriptionPlansData);

      expect(packages, hasLength(3));

      final basic = packages.first;
      expect(basic.id, '1');
      expect(basic.name, 'Basic');
      expect(basic.priceAmount, 99000);
      expect(basic.durationDays, 30);
      expect(basic.maxStores, 1);
      expect(basic.maxUsers, 5);
      expect(basic.features, [
        'Dashboard',
        'Quản lý menu cơ bản',
        'Quản lý đơn hàng',
      ]);
      expect(basic.isActive, isTrue);
      expect(basic.isDeleted, isFalse);
      expect(basic.createdAt, isNotNull);
      expect(basic.updatedAt, isNull);

      final enterprise = packages.last.toEntity();
      expect(enterprise.id, '3');
      expect(enterprise.maxStores, 999);
      expect(enterprise.maxUsers, 999);
      expect(enterprise.features, contains('Advanced analytics'));
    });

    test('maps empty package list', () {
      expect(ServicePackageModel.listFromJson(null), isEmpty);
    });
  });

  group('SubscriptionRemoteDataSource', () {
    test('loads plans from /subscription-plans', () async {
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
                  'message': 'Lay danh sach goi subscription thanh cong',
                  'data': _subscriptionPlansData,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = SubscriptionRemoteDataSource(DioClient(dio));

      final plans = await dataSource.getSubscriptionPlans();

      expect(requestedPath, '/subscription-plans');
      expect(plans, hasLength(3));
      expect(plans.first.name, 'Basic');
    });
  });
}

const _subscriptionPlansData = [
  {
    'id': 1,
    'name': 'Basic',
    'price': 99000,
    'durationDays': 30,
    'maxStores': 1,
    'maxUsers': 5,
    'features':
        '{"features": ["Dashboard", "Quản lý menu cơ bản", "Quản lý đơn hàng"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.703979Z',
    'updatedAt': null,
    'isDeleted': false,
  },
  {
    'id': 2,
    'name': 'Pro',
    'price': 299000,
    'durationDays': 30,
    'maxStores': 5,
    'maxUsers': 50,
    'features':
        '{"features": ["Dashboard nâng cao", "Quản lý menu đầy đủ", "Quản lý đơn hàng", "Báo cáo chi tiết", "Quản lý kho"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.704076Z',
    'updatedAt': null,
    'isDeleted': false,
  },
  {
    'id': 3,
    'name': 'Enterprise',
    'price': 999000,
    'durationDays': 30,
    'maxStores': 999,
    'maxUsers': 999,
    'features':
        '{"features": ["Tất cả tính năng Pro", "API access", "Custom integration", "Dedicated support", "Advanced analytics"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.704076Z',
    'updatedAt': null,
    'isDeleted': false,
  },
];
