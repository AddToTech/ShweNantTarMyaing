// lib/data/repositories/inventory_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/drift/app_database.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/product.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return InventoryRepository(apiClient: apiClient, db: db);
});

class InventoryRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;

  InventoryRepository({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  /// Adjust stock quantity or alert threshold manually
  Future<void> adjustStock({
    required String branchId,
    required String productId,
    double? newQuantity,
    double? deltaQuantity,
    String? reason,
    double? minAlertThreshold,
  }) async {
    final payload = <String, dynamic>{
      'branchId': branchId,
      'productId': productId,
      if (newQuantity != null) 'newQuantity': newQuantity,
      if (deltaQuantity != null) 'deltaQuantity': deltaQuantity,
      if (reason != null) 'reason': reason,
      if (minAlertThreshold != null) 'minAlertThreshold': minAlertThreshold,
    };

    try {
      await _apiClient.post('/inventory/adjust', body: payload);
    } catch (_) {
      // Local fallback in Drift if offline
      final existing = await (_db.select(_db.branchInventoriesCache)
            ..where((i) => i.branchId.equals(branchId) & i.productId.equals(productId)))
          .getSingleOrNull();

      if (existing != null) {
        final targetQty = newQuantity ?? (existing.stockQuantity + (deltaQuantity ?? 0.0));
        await (_db.update(_db.branchInventoriesCache)
              ..where((i) => i.id.equals(existing.id)))
            .write(
          BranchInventoriesCacheCompanion(
            stockQuantity: Value(targetQty.clamp(0, double.infinity)),
            minAlertThreshold: minAlertThreshold != null ? Value(minAlertThreshold) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  /// Get low stock items
  Future<List<BranchInventory>> getLowStockItems(String branchId) async {
    try {
      final data = await _apiClient.get('/inventory/low-stock/$branchId');
      if (data is List) {
        return data.map((json) {
          final map = json as Map<String, dynamic>;
          final prod = Product(
            id: map['product_id']?.toString() ?? '',
            categoryId: map['category_id']?.toString() ?? '',
            name: map['product_name']?.toString() ?? '',
            sku: map['sku']?.toString(),
            costPrice: (map['cost_price'] is num) ? (map['cost_price'] as num).toDouble() : 0.0,
            salePrice: (map['sale_price'] is num) ? (map['sale_price'] as num).toDouble() : 0.0,
            unitOfMeasure: 'piece',
            attributes: const {},
            isActive: true,
          );

          return BranchInventory(
            id: map['id']?.toString() ?? '${branchId}_${prod.id}',
            branchId: branchId,
            productId: prod.id,
            product: prod,
            stockQuantity: (map['stock_quantity'] is num) ? (map['stock_quantity'] as num).toDouble() : 0.0,
            minAlertThreshold: (map['min_alert_threshold'] is num) ? (map['min_alert_threshold'] as num).toDouble() : 5.0,
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }
}
