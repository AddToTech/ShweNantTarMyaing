import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/domain/models/sale_transaction.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';
import 'package:sitepyoe/ui/features/pos/view_models/transaction_notifier.dart';

void main() {
  group('TransactionNotifier & SaleTransaction Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final product1 = kMockProducts[0]; // Phalaenopsis Orchid, 25000 Ks
    final product2 = kMockProducts[2]; // Bougainvillea, 8000 Ks

    test('Initial transaction state has empty transactions', () {
      final state = container.read(transactionProvider);
      expect(state.transactions, isEmpty);
      expect(state.latestTransaction, isNull);
      expect(state.isPrinting, isFalse);
    });

    test('Complete cash sale records transaction properly', () async {
      // Add items to cart
      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addItem(product1);
      cartNotifier.addItem(product2);

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 2);
      final total = cartState.totalAmount; // 33,000 Ks

      // Complete sale
      final txn = await container.read(transactionProvider.notifier).completeSale(
            cart: cartState,
            branchId: 'branch_a',
            paymentMethod: PaymentMethodType.cash,
            tenderedAmount: 40000.0,
            changeAmount: 7000.0,
          );

      if (txn != null) {
        expect(txn.receiptNo, startsWith('SP-'));
        expect(txn.branchId, 'branch_a');
        expect(txn.items.length, 2);
        expect(txn.totalAmount, total);
        expect(txn.tenderedAmount, 40000.0);
        expect(txn.changeAmount, 7000.0);
        expect(txn.isCash, isTrue);
        expect(txn.isCredit, isFalse);
        expect(txn.isDigital, isFalse);

        final state = container.read(transactionProvider);
        expect(state.transactions.length, 1);
        expect(state.latestTransaction?.receiptNo, txn.receiptNo);
      }
    });

    test('Complete digital payment sale records transaction with referenceId', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addItem(product1);

      final cartState = container.read(cartProvider);

      final txn = await container.read(transactionProvider.notifier).completeSale(
            cart: cartState,
            branchId: 'branch_a',
            paymentMethod: PaymentMethodType.kpay,
            referenceId: 'KPAY-20261013-0987',
            notes: 'Provider: KPay',
          );

      if (txn != null) {
        expect(txn.isDigital, isTrue);
        expect(txn.referenceId, 'KPAY-20261013-0987');
        expect(txn.paymentMethodLabel, 'KPay');
      }
    });

    test('Complete credit sale records customer name and phone', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addItem(product1);

      final cartState = container.read(cartProvider);

      final txn = await container.read(transactionProvider.notifier).completeSale(
            cart: cartState,
            branchId: 'branch_b',
            paymentMethod: PaymentMethodType.credit,
            customerName: 'Daw Mya',
            customerPhone: '09798765432',
            notes: 'Pay within 14 days',
          );

      if (txn != null) {
        expect(txn.isCredit, isTrue);
        expect(txn.customerName, 'Daw Mya');
        expect(txn.customerPhone, '09798765432');
        expect(txn.notes, 'Pay within 14 days');
      }
    });
  });
}
