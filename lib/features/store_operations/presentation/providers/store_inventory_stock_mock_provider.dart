import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryStockMockProvider =
    Provider<List<StoreInventoryStockMockItem>>((ref) {
      // TODO: Replace mock data when inventory stock API contract is available.
      return const [
        StoreInventoryStockMockItem(
          name: 'Thăng Long',
          sku: 'SP0048',
          stockText: '9/9',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Sài gòn bạc',
          sku: 'SP0038',
          stockText: '1/1',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Number 1',
          sku: 'SP0072',
          stockText: '3/3',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Sữa đậu nành',
          sku: 'SP0135',
          stockText: '0/0',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Mèo mi',
          sku: 'SP0044',
          stockText: '2/2',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Bí đao',
          sku: 'SP0075',
          stockText: '3/3',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'C2 đào',
          sku: 'SP0070',
          stockText: '3/3',
          secondaryQuantity: '0',
        ),
        StoreInventoryStockMockItem(
          name: 'Coca',
          sku: 'SP0050',
          stockText: '4/4',
          secondaryQuantity: '0',
        ),
      ];
    });

class StoreInventoryStockMockItem {
  final String name;
  final String sku;
  final String stockText;
  final String secondaryQuantity;

  const StoreInventoryStockMockItem({
    required this.name,
    required this.sku,
    required this.stockText,
    required this.secondaryQuantity,
  });
}
