import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryImportIngredientsMockProvider =
    Provider<List<StoreInventoryImportIngredientMockItem>>((ref) {
      // TODO: Replace mock data when inventory import ingredients API is available.
      return const [
        StoreInventoryImportIngredientMockItem(
          name: 'Đường',
          code: 'NL0001',
          stockQuantity: 12,
          unit: 'kg',
        ),
        StoreInventoryImportIngredientMockItem(
          name: 'Sữa tươi',
          code: 'NL0002',
          stockQuantity: 8,
          unit: 'lít',
        ),
        StoreInventoryImportIngredientMockItem(
          name: 'Trà ô long',
          code: 'NL0003',
          stockQuantity: 6,
          unit: 'kg',
        ),
        StoreInventoryImportIngredientMockItem(
          name: 'Bột cacao',
          code: 'NL0004',
          stockQuantity: 4,
          unit: 'kg',
        ),
        StoreInventoryImportIngredientMockItem(
          name: 'Chanh',
          code: 'NL0005',
          stockQuantity: 30,
          unit: 'quả',
        ),
        StoreInventoryImportIngredientMockItem(
          name: 'Mật ong',
          code: 'NL0006',
          stockQuantity: 5,
          unit: 'lít',
        ),
      ];
    });

class StoreInventoryImportIngredientMockItem {
  final String name;
  final String code;
  final int stockQuantity;
  final String unit;

  const StoreInventoryImportIngredientMockItem({
    required this.name,
    required this.code,
    required this.stockQuantity,
    required this.unit,
  });
}
