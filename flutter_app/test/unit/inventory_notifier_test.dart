import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';

void main() {
  group('InventoryNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial stock for branches is properly populated', () {
      final state = container.read(inventoryProvider);
      final orchidStockA = state.getStock('branch_a', 'p001');
      final orchidStockB = state.getStock('branch_b', 'p001');

      expect(orchidStockA, 12);
      expect(orchidStockB, 8);
    });

    test('deductStock succeeds when quantity <= available and fails when exceeding', () {
      final notifier = container.read(inventoryProvider.notifier);

      // Deduct 2 from branch_a (initial 12)
      final success = notifier.deductStock('branch_a', 'p001', 2);
      expect(success, isTrue);
      expect(container.read(inventoryProvider).getStock('branch_a', 'p001'), 10);

      // Attempt to deduct more than remaining (15 > 10)
      final fail = notifier.deductStock('branch_a', 'p001', 15);
      expect(fail, isFalse);
      expect(container.read(inventoryProvider).getStock('branch_a', 'p001'), 10);
    });

    test('addStock increments stock properly', () {
      final notifier = container.read(inventoryProvider.notifier);
      notifier.addStock('branch_b', 'p001', 5);
      expect(container.read(inventoryProvider).getStock('branch_b', 'p001'), 13);
    });

    test('setStock updates physical count correctly', () {
      final notifier = container.read(inventoryProvider.notifier);
      notifier.setStock('branch_a', 'p001', 25);
      expect(container.read(inventoryProvider).getStock('branch_a', 'p001'), 25);
    });

    test('lowStockAlertProvider detects items with stock <= minStock', () {
      final lowStockItemsA = container.read(lowStockAlertProvider('branch_a'));
      expect(lowStockItemsA, isNotEmpty);

      // p010 has 0 stock in branch_a
      final outOfStockItem = lowStockItemsA.firstWhere((i) => i.product.id == 'p010');
      expect(outOfStockItem.stock, 0);
      expect(outOfStockItem.isOutOfStock, isTrue);
    });

    test('catalogProvider addProduct adds item and initializes branch stock', () {
      final initialCount = container.read(catalogProvider).length;
      const newProd = MockProduct(
        id: 'p_test',
        name: 'Monstera Deliciosa',
        category: ProductCategory.plants,
        subcategory: 'Indoor',
        originType: OriginType.thaiImport,
        salePrice: 35000,
        costPrice: 20000,
        stock: 15,
      );

      container.read(catalogProvider.notifier).addProduct(
            newProd,
            stockBranchA: 15,
            stockBranchB: 10,
          );

      expect(container.read(catalogProvider).length, initialCount + 1);
      expect(container.read(inventoryProvider).getStock('branch_a', 'p_test'), 15);
      expect(container.read(inventoryProvider).getStock('branch_b', 'p_test'), 10);

      // Verify branchInventoryProvider reflects new product
      final branchAProducts = container.read(branchInventoryProvider('branch_a'));
      final added = branchAProducts.firstWhere((p) => p.product.id == 'p_test');
      expect(added.stock, 15);
    });
  });
}
