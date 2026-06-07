import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryExportProductsMockProvider =
    Provider<List<StoreInventoryExportProductMockItem>>((ref) {
      // TODO: Replace mock data when inventory export products API is available.
      return const [
        StoreInventoryExportProductMockItem(
          name: 'Revive',
          sku: 'SP0098',
          stockQuantity: 4,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Ô long tea',
          sku: 'SP0082',
          stockQuantity: 7,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Bí đao',
          sku: 'SP0075',
          stockQuantity: 4,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Coca',
          sku: 'SP0050',
          stockQuantity: 7,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Bò cụng redbull',
          sku: 'SP0039',
          stockQuantity: 8,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Mèo mi',
          sku: 'SP0044',
          stockQuantity: 3,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Revive chanh muối',
          sku: 'SP0068',
          stockQuantity: 5,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Number 1 chanh',
          sku: 'SP0088',
          stockQuantity: 0,
        ),
        StoreInventoryExportProductMockItem(
          name: 'Lipovitan tăng lực mật ong',
          sku: 'SP0080',
          stockQuantity: 0,
        ),
      ];
    });

class StoreInventoryExportProductMockItem {
  final String name;
  final String sku;
  final int stockQuantity;

  const StoreInventoryExportProductMockItem({
    required this.name,
    required this.sku,
    required this.stockQuantity,
  });
}
