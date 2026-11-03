import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';

void main() {
  group('Held Orders Queue & CartNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final product1 = kMockProducts[0]; // Phalaenopsis Orchid
    final product2 = kMockProducts[1]; // Monstera Deliciosa

    test('Initial cart state has empty held orders', () {
      final cart = container.read(cartProvider);
      expect(cart.heldOrders, isEmpty);
      expect(cart.ticketNumber, 'SP-001');
    });

    test('holdCurrentCart returns null if cart is empty', () {
      final held = container.read(cartProvider.notifier).holdCurrentCart();
      expect(held, isNull);
      expect(container.read(cartProvider).heldOrders, isEmpty);
    });

    test('holdCurrentCart adds order to held queue and resets active cart with new ticket', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(product1);
      notifier.addItem(product2);
      notifier.setOrderDiscount(2000.0);

      final held = notifier.holdCurrentCart(
        customerName: 'Ko Kyaw Swar',
        note: 'Stepped out to ATM',
      );

      expect(held, isNotNull);
      expect(held!.ticketNumber, 'SP-001');
      expect(held.customerName, 'Ko Kyaw Swar');
      expect(held.note, 'Stepped out to ATM');
      expect(held.items.length, 2);
      expect(held.orderDiscountAmount, 2000.0);

      // Verify active cart state
      final currentCart = container.read(cartProvider);
      expect(currentCart.isEmpty, isTrue);
      expect(currentCart.ticketNumber, 'SP-002');
      expect(currentCart.heldOrders.length, 1);
      expect(currentCart.heldOrders.first.id, held.id);
    });

    test('resumeHeldOrder restores items and ticket number into active cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(product1);
      final held = notifier.holdCurrentCart(customerName: 'Customer A');
      expect(held, isNotNull);

      // Active cart is now SP-002 and empty
      expect(container.read(cartProvider).isEmpty, isTrue);

      // Resume held order
      notifier.resumeHeldOrder(held!.id);

      final resumedCart = container.read(cartProvider);
      expect(resumedCart.items.length, 1);
      expect(resumedCart.items.first.product.id, product1.id);
      expect(resumedCart.ticketNumber, 'SP-001');
      expect(resumedCart.heldOrders, isEmpty);
    });

    test('resumeHeldOrder auto-parks current active items into held queue', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(product1);
      final held1 = notifier.holdCurrentCart(); // Held #SP-001

      // Add product2 into current active cart (SP-002)
      notifier.addItem(product2);
      expect(container.read(cartProvider).items.length, 1);

      // Resume held1
      notifier.resumeHeldOrder(held1!.id);

      final cartState = container.read(cartProvider);
      // Active cart is now held1 items (product1)
      expect(cartState.items.first.product.id, product1.id);
      // And the previous active cart (product2) was parked into held queue
      expect(cartState.heldOrders.length, 1);
      expect(cartState.heldOrders.first.items.first.product.id, product2.id);
    });

    test('discardHeldOrder removes held order from queue', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(product1);
      final held = notifier.holdCurrentCart();
      expect(container.read(cartProvider).heldOrders.length, 1);

      notifier.discardHeldOrder(held!.id);
      expect(container.read(cartProvider).heldOrders, isEmpty);
    });

    test('clear preserves held orders queue', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(product1);
      final held = notifier.holdCurrentCart();
      expect(held, isNotNull);

      // Add new item to current cart
      notifier.addItem(product2);
      expect(container.read(cartProvider).items.length, 1);

      // Clear current cart
      notifier.clear();
      final state = container.read(cartProvider);
      expect(state.isEmpty, isTrue);
      // Held queue must still retain the held order!
      expect(state.heldOrders.length, 1);
    });
  });
}
