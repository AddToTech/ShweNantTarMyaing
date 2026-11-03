import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/wastage/view_models/wastage_notifier.dart';

void main() {
  group('WastageNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial seeded wastage records exist and compute total loss', () {
      final state = container.read(wastageProvider);
      expect(state.entries, isNotEmpty);
      expect(state.totalLoss, greaterThan(0));
      expect(state.totalQuantity, greaterThan(0));
    });

    test('recordWastage deducts stock from inventory and logs debit record', () {
      final product = kMockProducts.firstWhere((p) => p.id == 'p001'); // 12 in stock, 15000 cost
      final initialStock = container.read(inventoryProvider).getStock('branch_a', 'p001');
      expect(initialStock, 12);

      final initialEntryCount = container.read(wastageProvider).entries.length;

      final success = container.read(wastageProvider.notifier).recordWastage(
            branchId: 'branch_a',
            product: product,
            quantity: 2,
            reason: WastageReasonOption.deadWithered,
            notes: 'Test plant wilted',
          );

      expect(success, isTrue);

      // Verify inventory deducted
      final newStock = container.read(inventoryProvider).getStock('branch_a', 'p001');
      expect(newStock, 10);

      // Verify wastage log recorded
      final newEntries = container.read(wastageProvider).entries;
      expect(newEntries.length, initialEntryCount + 1);

      final latest = newEntries.first;
      expect(latest.productId, 'p001');
      expect(latest.quantity, 2);
      expect(latest.unitCost, 15000);
      expect(latest.totalCostLoss, 30000);
      expect(latest.reason, WastageReasonOption.deadWithered);
      expect(latest.notes, 'Test plant wilted');
    });

    test('recordWastage rejects quantity exceeding available stock', () {
      final product = kMockProducts.firstWhere((p) => p.id == 'p001'); // 12 in stock

      final fail = container.read(wastageProvider.notifier).recordWastage(
            branchId: 'branch_a',
            product: product,
            quantity: 50, // Exceeds 12
            reason: WastageReasonOption.pestInfestation,
          );

      expect(fail, isFalse);
      expect(container.read(inventoryProvider).getStock('branch_a', 'p001'), 12);
    });

    test('Filtering wastage by reason and branch works properly', () {
      final notifier = container.read(wastageProvider.notifier);

      notifier.setBranchFilter('branch_a');
      var state = container.read(wastageProvider);
      for (final e in state.filteredEntries) {
        expect(e.branchId, 'branch_a');
      }

      notifier.setReasonFilter(WastageReasonOption.brokenCracked);
      state = container.read(wastageProvider);
      for (final e in state.filteredEntries) {
        expect(e.reason, WastageReasonOption.brokenCracked);
      }
    });
  });
}
