import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';

void main() {
  group('CartNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final testProduct1 = kMockProducts[0]; // Phalaenopsis Orchid, 18000 Ks
    final testProduct2 = kMockProducts[1]; // Monstera Deliciosa, 25000 Ks

    test('Initial cart state is empty', () {
      final cart = container.read(cartProvider);
      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.totalAmount, 0.0);
      expect(cart.isEmpty, isTrue);
    });

    test('Adding product adds item with quantity 1', () {
      container.read(cartProvider.notifier).addItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, testProduct1.id);
      expect(cart.items.first.quantity, 1);
      expect(cart.itemCount, 1);
      expect(cart.subtotal, testProduct1.salePrice);
      expect(cart.totalAmount, testProduct1.salePrice);
    });

    test('Adding same product increments existing item quantity', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1);
      notifier.addItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, testProduct1.salePrice * 2);
    });

    test('Adding distinct products keeps multiple items', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1);
      notifier.addItem(testProduct2);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 2);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, testProduct1.salePrice + testProduct2.salePrice);
    });

    test('Increment and Decrement work as expected', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1);
      notifier.increment(testProduct1.id);

      expect(container.read(cartProvider).items.first.quantity, 2);

      notifier.decrement(testProduct1.id);
      expect(container.read(cartProvider).items.first.quantity, 1);

      // Decrementing when quantity == 1 removes the item
      notifier.decrement(testProduct1.id);
      expect(container.read(cartProvider).items, isEmpty);
    });

    test('Remove deletes item from cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1);
      notifier.addItem(testProduct2);

      notifier.remove(testProduct1.id);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, testProduct2.id);
    });

    test('Line item discount percentage applies correctly', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1); // 25,000 Ks
      notifier.setItemDiscount(testProduct1.id, 10.0); // 10% off = 22,500 Ks

      final cart = container.read(cartProvider);
      final expectedLineTotal = testProduct1.salePrice * 0.9;
      expect(cart.items.first.discountPct, 10.0);
      expect(cart.items.first.lineTotal, expectedLineTotal);
      expect(cart.subtotal, expectedLineTotal);
      expect(cart.totalAmount, expectedLineTotal);
    });

    test('Order-level discount applies correctly to total', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1); // 25,000 Ks
      notifier.setOrderDiscount(3000.0);

      final cart = container.read(cartProvider);
      expect(cart.subtotal, testProduct1.salePrice);
      expect(cart.orderDiscountAmount, 3000.0);
      expect(cart.totalAmount, testProduct1.salePrice - 3000.0);
    });

    test('Clear resets the entire cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(testProduct1);
      notifier.addItem(testProduct2);
      notifier.setOrderDiscount(5000.0);

      notifier.clear();

      final cart = container.read(cartProvider);
      expect(cart.isEmpty, isTrue);
      expect(cart.orderDiscountAmount, 0.0);
      expect(cart.totalAmount, 0.0);
    });
  });
}
