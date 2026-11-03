import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/branch_transfer/view_models/transfer_notifier.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';

void main() {
  group('TransferNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial seeded transfers include in-transit and received vouchers', () {
      final state = container.read(transferProvider);
      expect(state.vouchers, isNotEmpty);

      final hasInTransit = state.vouchers.any((v) => v.status == TransferVoucherStatus.inTransit);
      final hasReceived = state.vouchers.any((v) => v.status == TransferVoucherStatus.received);

      expect(hasInTransit, isTrue);
      expect(hasReceived, isTrue);
    });

    test('createTransfer deducts from source branch and marks voucher In-Transit', () {
      final initialStockA = container.read(inventoryProvider).getStock('branch_a', 'p001'); // 12
      final initialVouchers = container.read(transferProvider).vouchers.length;

      final success = container.read(transferProvider.notifier).createTransfer(
            fromBranchId: 'branch_a',
            toBranchId: 'branch_b',
            items: const [
              TransferItemRecord(
                productId: 'p001',
                productName: 'Phalaenopsis Orchid',
                quantity: 4,
                unitCost: 15000,
                category: ProductCategory.plants,
                originType: OriginType.thaiImport,
              ),
            ],
            notes: 'Test urgent transfer',
          );

      expect(success, isTrue);

      // Verify stock decremented at source
      final newStockA = container.read(inventoryProvider).getStock('branch_a', 'p001');
      expect(newStockA, initialStockA - 4); // 8

      // Verify voucher state
      final vouchers = container.read(transferProvider).vouchers;
      expect(vouchers.length, initialVouchers + 1);

      final latest = vouchers.first;
      expect(latest.status, TransferVoucherStatus.inTransit);
      expect(latest.fromBranchId, 'branch_a');
      expect(latest.toBranchId, 'branch_b');
      expect(latest.totalQuantity, 4);
    });

    test('createTransfer fails if fromBranch == toBranch', () {
      final fail = container.read(transferProvider.notifier).createTransfer(
            fromBranchId: 'branch_a',
            toBranchId: 'branch_a',
            items: const [
              TransferItemRecord(
                productId: 'p001',
                productName: 'Phalaenopsis Orchid',
                quantity: 2,
                unitCost: 15000,
                category: ProductCategory.plants,
              ),
            ],
          );

      expect(fail, isFalse);
    });

    test('receiveTransfer marks voucher received and increments destination stock', () {
      // Create transfer first: 3 of p002 from branch_a to branch_b
      final initialStockB = container.read(inventoryProvider).getStock('branch_b', 'p002'); // 15

      container.read(transferProvider.notifier).createTransfer(
            fromBranchId: 'branch_a',
            toBranchId: 'branch_b',
            items: const [
              TransferItemRecord(
                productId: 'p002',
                productName: 'Golden Money Tree',
                quantity: 3,
                unitCost: 10000,
                category: ProductCategory.plants,
              ),
            ],
          );

      final voucher = container.read(transferProvider).vouchers.first;
      expect(voucher.status, TransferVoucherStatus.inTransit);

      // Confirm receipt
      final success = container.read(transferProvider.notifier).receiveTransfer(voucher.id);
      expect(success, isTrue);

      // Verify stock incremented at destination
      final newStockB = container.read(inventoryProvider).getStock('branch_b', 'p002');
      expect(newStockB, initialStockB + 3); // 18

      // Verify voucher status updated
      final updatedVoucher = container.read(transferProvider).vouchers.firstWhere((v) => v.id == voucher.id);
      expect(updatedVoucher.status, TransferVoucherStatus.received);
      expect(updatedVoucher.receivedAt, isNotNull);
    });
  });
}
