import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryImportMockProvider =
    Provider<List<StoreInventoryImportMockItem>>((ref) {
      // TODO: Replace mock data when inventory import API contract is available.
      return const [
        StoreInventoryImportMockItem(
          code: '#NH265',
          createdAtText: '13:01 27/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '3.500',
          paymentStatus: 'Đã thanh toán',
        ),
        StoreInventoryImportMockItem(
          code: '#NH264',
          createdAtText: '13:05 24/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '0',
          paymentStatus: 'Đã thanh toán',
        ),
        StoreInventoryImportMockItem(
          code: '#NH263',
          createdAtText: '08:59 22/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '0',
          paymentStatus: 'Đã thanh toán',
        ),
        StoreInventoryImportMockItem(
          code: '#NH262',
          createdAtText: '20:03 19/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '0',
          paymentStatus: 'Đã thanh toán',
        ),
        StoreInventoryImportMockItem(
          code: '#NH261',
          createdAtText: '21:00 16/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '0',
          paymentStatus: 'Đã thanh toán',
        ),
      ];
    });

class StoreInventoryImportMockItem {
  final String code;
  final String createdAtText;
  final String status;
  final String creatorName;
  final String totalText;
  final String paymentStatus;

  const StoreInventoryImportMockItem({
    required this.code,
    required this.createdAtText,
    required this.status,
    required this.creatorName,
    required this.totalText,
    required this.paymentStatus,
  });
}
