import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/vendor_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';

void main() {
  group('VendorNotifier & activeVendorsProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state contains kDemoVendors', () {
      final vendors = container.read(vendorProvider);
      expect(vendors.length, kDemoVendors.length);
      expect(vendors.any((v) => v.id == 'v001'), isTrue);
    });

    test('activeVendorsProvider filters out inactive vendors and sorts alphabetically', () {
      final notifier = container.read(vendorProvider.notifier);
      // Toggle v001 to inactive
      notifier.toggleActive('v001');

      final active = container.read(activeVendorsProvider);
      expect(active.any((v) => v.id == 'v001'), isFalse);

      // Verify sorted alphabetically
      for (int i = 0; i < active.length - 1; i++) {
        expect(active[i].name.compareTo(active[i + 1].name) <= 0, isTrue);
      }
    });

    test('addVendor adds a new vendor with valid properties', () {
      final notifier = container.read(vendorProvider.notifier);
      final countBefore = container.read(vendorProvider).length;

      notifier.addVendor(
        name: 'အမေများ စိုက်ပျိုးရေး ခြံ',
        phone: '09-777-888-999',
        address: 'ပြင်ဦးလွင်',
        notes: 'နှင်းဆီနှင့် သစ်ခွမျိုးများ',
      );

      final vendors = container.read(vendorProvider);
      expect(vendors.length, countBefore + 1);

      final added = vendors.last;
      expect(added.name, 'အမေများ စိုက်ပျိုးရေး ခြံ');
      expect(added.phone, '09-777-888-999');
      expect(added.address, 'ပြင်ဦးလွင်');
      expect(added.notes, 'နှင်းဆီနှင့် သစ်ခွမျိုးများ');
      expect(added.isActive, isTrue);
      expect(added.id, isNotEmpty);
    });

    test('updateVendor updates existing vendor details', () {
      final notifier = container.read(vendorProvider.notifier);
      final original = container.read(vendorProvider).firstWhere((v) => v.id == 'v002');

      final updated = original.copyWith(
        name: 'မြဝတီ ပြည်တွင်း/ပြည်ပ အပင်ကြီးများ',
        phone: '09-111-222-333',
      );

      notifier.updateVendor(updated);

      final after = container.read(vendorProvider).firstWhere((v) => v.id == 'v002');
      expect(after.name, 'မြဝတီ ပြည်တွင်း/ပြည်ပ အပင်ကြီးများ');
      expect(after.phone, '09-111-222-333');
      expect(after.address, original.address);
    });

    test('toggleActive flips the isActive flag', () {
      final notifier = container.read(vendorProvider.notifier);
      final before = container.read(vendorProvider).firstWhere((v) => v.id == 'v003');
      expect(before.isActive, isTrue);

      notifier.toggleActive('v003');
      final toggledOff = container.read(vendorProvider).firstWhere((v) => v.id == 'v003');
      expect(toggledOff.isActive, isFalse);

      notifier.toggleActive('v003');
      final toggledOn = container.read(vendorProvider).firstWhere((v) => v.id == 'v003');
      expect(toggledOn.isActive, isTrue);
    });

    test('deleteVendor removes vendor by ID', () {
      final notifier = container.read(vendorProvider.notifier);
      final countBefore = container.read(vendorProvider).length;

      notifier.deleteVendor('v004');

      final vendors = container.read(vendorProvider);
      expect(vendors.length, countBefore - 1);
      expect(vendors.any((v) => v.id == 'v004'), isFalse);
    });
  });

  group('PurchaseNotifier & vendorPayablesProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial purchase state has empty purchase list', () {
      final state = container.read(purchaseProvider);
      expect(state.purchases, isEmpty);
    });

    test('submitPurchase saves purchase with generated PO number', () {
      final notifier = container.read(purchaseProvider.notifier);

      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        vendorName: 'ကိုကိုမြိုင် သစ်ပင်ကုန်သည်',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p001',
            productName: 'Phalaenopsis Orchid',
            quantity: 10,
            unitCost: 16000,
          ),
        ],
        discount: 5000,
        paidAmount: 155000,
        paymentStatus: PurchasePaymentStatus.paid,
        notes: 'Regular restock',
        createdBy: 'Admin',
      );

      final state = container.read(purchaseProvider);
      expect(state.purchases.length, 1);

      final p = state.purchases.first;
      expect(p.purchaseNo, startsWith('PO-'));
      expect(p.branchId, 'branch_a');
      expect(p.vendorId, 'v001');
      expect(p.items.length, 1);
      expect(p.subtotal, 160000);
      expect(p.totalAmount, 155000);
      expect(p.paidAmount, 155000);
      expect(p.balanceDue, 0);
      expect(p.paymentStatus, PurchasePaymentStatus.paid);
    });

    test('submitPurchase auto-increments branch inventory for purchased items', () {
      final initialStock = container.read(inventoryProvider).getStock('branch_a', 'p002');

      final notifier = container.read(purchaseProvider.notifier);
      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v002',
        vendorName: 'မြဝတီ ပြည်တွင်းပင် ပေါင်းစုံ',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p002',
            productName: 'Fiddle Leaf Fig',
            quantity: 15,
            unitCost: 20000,
          ),
        ],
        discount: 0,
        paidAmount: 300000,
        paymentStatus: PurchasePaymentStatus.paid,
      );

      final newStock = container.read(inventoryProvider).getStock('branch_a', 'p002');
      expect(newStock, initialStock + 15);
    });

    test('submitPurchase updates product costPrice in catalog', () {
      final notifier = container.read(purchaseProvider.notifier);
      const newCost = 17500.0;

      notifier.submitPurchase(
        branchId: 'branch_b',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p001',
            productName: 'Phalaenopsis Orchid',
            quantity: 5,
            unitCost: newCost,
          ),
        ],
        discount: 0,
        paidAmount: 87500,
        paymentStatus: PurchasePaymentStatus.paid,
      );

      final product = container.read(catalogProvider).firstWhere((p) => p.id == 'p001');
      expect(product.costPrice, newCost);
    });

    test('vendorPayablesProvider accurately tracks unpaid and partial debts', () {
      final notifier = container.read(purchaseProvider.notifier);

      // 1. Unpaid purchase of 200,000 MMK for vendor v001
      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p003',
            productName: 'Monstera Deliciosa',
            quantity: 10,
            unitCost: 20000,
          ),
        ],
        discount: 0,
        paidAmount: 0,
        paymentStatus: PurchasePaymentStatus.unpaid,
      );

      expect(container.read(vendorPayablesProvider('v001')), 200000);

      // 2. Partial purchase of 100,000 MMK with 40,000 MMK paid (balanceDue = 60,000) for vendor v001
      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p004',
            productName: 'Sansevieria Trifasciata',
            quantity: 10,
            unitCost: 10000,
          ),
        ],
        discount: 0,
        paidAmount: 40000,
        paymentStatus: PurchasePaymentStatus.partial,
      );

      // Total payable for v001 should be 200,000 + 60,000 = 260,000 MMK
      expect(container.read(vendorPayablesProvider('v001')), 260000);

      // 3. Fully paid purchase for v001 should not increase payables
      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(
            productId: 'p005',
            productName: 'Peace Lily',
            quantity: 5,
            unitCost: 8000,
          ),
        ],
        discount: 0,
        paidAmount: 40000,
        paymentStatus: PurchasePaymentStatus.paid,
      );

      expect(container.read(vendorPayablesProvider('v001')), 260000);

      // 4. Other vendor payables remain 0
      expect(container.read(vendorPayablesProvider('v002')), 0);
    });

    test('getPurchasesByBranch and getPurchasesByVendor filter correctly', () {
      final notifier = container.read(purchaseProvider.notifier);

      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(productId: 'p001', productName: 'Item 1', quantity: 1, unitCost: 1000),
        ],
        discount: 0,
        paidAmount: 1000,
        paymentStatus: PurchasePaymentStatus.paid,
      );

      notifier.submitPurchase(
        branchId: 'branch_b',
        vendorId: 'v002',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(productId: 'p002', productName: 'Item 2', quantity: 2, unitCost: 2000),
        ],
        discount: 0,
        paidAmount: 4000,
        paymentStatus: PurchasePaymentStatus.paid,
      );

      expect(notifier.getPurchasesByBranch('branch_a').length, 1);
      expect(notifier.getPurchasesByBranch('branch_b').length, 1);
      expect(notifier.getPurchasesByBranch('branch_other').length, 0);

      expect(notifier.getPurchasesByVendor('v001').length, 1);
      expect(notifier.getPurchasesByVendor('v002').length, 1);
      expect(notifier.getPurchasesByVendor('v003').length, 0);
    });

    test('recordPayment settles unpaid purchase to paid and updates vendor payables', () {
      final notifier = container.read(purchaseProvider.notifier);

      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(productId: 'p001', productName: 'Item 1', quantity: 5, unitCost: 10000),
        ],
        discount: 0,
        paidAmount: 0,
        paymentStatus: PurchasePaymentStatus.unpaid,
      );

      final purchase = container.read(purchaseProvider).purchases.first;
      expect(purchase.paymentStatus, PurchasePaymentStatus.unpaid);
      expect(purchase.balanceDue, 50000);
      expect(container.read(vendorPayablesProvider('v001')), 50000);

      // Record full payment
      notifier.recordPayment(
        purchaseId: purchase.id,
        paymentAmount: 50000,
        note: 'Cash full settlement',
      );

      final updatedPurchase = container.read(purchaseProvider).purchases.firstWhere((p) => p.id == purchase.id);
      expect(updatedPurchase.paymentStatus, PurchasePaymentStatus.paid);
      expect(updatedPurchase.paidAmount, 50000);
      expect(updatedPurchase.balanceDue, 0);
      expect(updatedPurchase.notes, contains('Cash full settlement'));
      expect(container.read(vendorPayablesProvider('v001')), 0);
    });

    test('recordPayment handles partial payments correctly', () {
      final notifier = container.read(purchaseProvider.notifier);

      notifier.submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v002',
        purchaseDate: DateTime.now(),
        items: const [
          PurchaseItem(productId: 'p002', productName: 'Item 2', quantity: 2, unitCost: 40000),
        ],
        discount: 0,
        paidAmount: 0,
        paymentStatus: PurchasePaymentStatus.unpaid,
      );

      final purchase = container.read(purchaseProvider).purchases.first;
      expect(purchase.totalAmount, 80000);

      // Step 1: Pay 30,000 MMK partially
      notifier.recordPayment(
        purchaseId: purchase.id,
        paymentAmount: 30000,
        note: 'Partial KPay',
      );

      var updated = container.read(purchaseProvider).purchases.firstWhere((p) => p.id == purchase.id);
      expect(updated.paymentStatus, PurchasePaymentStatus.partial);
      expect(updated.paidAmount, 30000);
      expect(updated.balanceDue, 50000);
      expect(container.read(vendorPayablesProvider('v002')), 50000);

      // Step 2: Pay remaining 50,000 MMK
      notifier.recordPayment(
        purchaseId: purchase.id,
        paymentAmount: 50000,
        note: 'Settling remaining balance',
      );

      updated = container.read(purchaseProvider).purchases.firstWhere((p) => p.id == purchase.id);
      expect(updated.paymentStatus, PurchasePaymentStatus.paid);
      expect(updated.paidAmount, 80000);
      expect(updated.balanceDue, 0);
      expect(container.read(vendorPayablesProvider('v002')), 0);
    });
  });
}
