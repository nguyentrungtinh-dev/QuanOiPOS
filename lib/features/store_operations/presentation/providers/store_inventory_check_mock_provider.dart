import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryCheckMockProvider =
    Provider<List<StoreInventoryCheckMockItem>>((ref) {
      // TODO: Replace mock data when inventory check API contract is available.
      return const [];
    });

class StoreInventoryCheckMockItem {
  final String code;
  final String title;
  final String status;
  final String createdBy;

  const StoreInventoryCheckMockItem({
    required this.code,
    required this.title,
    required this.status,
    required this.createdBy,
  });
}
