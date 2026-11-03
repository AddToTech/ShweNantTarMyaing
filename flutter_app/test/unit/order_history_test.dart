import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/domain/models/sale_transaction.dart';
import 'package:sitepyoe/ui/features/orders/view_models/order_history_notifier.dart';

void main() {
  group('Order History State & Filtering Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial filter defaults to Today date filter', () {
      final filter = container.read(orderHistoryFilterProvider);
      expect(filter.dateFilter, OrderDateFilter.today);
      expect(filter.branchId, 'all');
      expect(filter.paymentMethod, isNull);
      expect(filter.searchQuery, isEmpty);
    });

    test('Today filter returns only transactions created today', () {
      final filtered = container.read(filteredOrderHistoryProvider);
      final now = DateTime.now();

      expect(filtered, isNotEmpty);
      expect(
        filtered.every((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day),
        isTrue,
      );
      // Our baseline seed has 3 transactions today: 1001, 1002, 1003
      expect(filtered.length, 3);
    });

    test('Yesterday filter returns only transactions created yesterday', () {
      final notifier = container.read(orderHistoryFilterProvider.notifier);
      notifier.setDateFilter(OrderDateFilter.yesterday);

      final filtered = container.read(filteredOrderHistoryProvider);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(filtered, isNotEmpty);
      expect(
        filtered.every((s) =>
            s.createdAt.year == yesterday.year &&
            s.createdAt.month == yesterday.month &&
            s.createdAt.day == yesterday.day),
        isTrue,
      );
      expect(filtered.length, 1);
      expect(filtered.first.receiptNo, 'SP-20261012-1004');
    });

    test('All Time filter returns all seeded transactions', () {
      final notifier = container.read(orderHistoryFilterProvider.notifier);
      notifier.setDateFilter(OrderDateFilter.allTime);

      final filtered = container.read(filteredOrderHistoryProvider);
      expect(filtered.length, 6);
    });

    test('Branch filtering filters orders by branchId', () {
      final notifier = container.read(orderHistoryFilterProvider.notifier);
      notifier.setDateFilter(OrderDateFilter.allTime);
      notifier.setBranch('branch_a');

      final filtered = container.read(filteredOrderHistoryProvider);
      expect(filtered.every((s) => s.branchId == 'branch_a'), isTrue);
    });

    test('Payment method filter isolates specific payment type', () {
      final notifier = container.read(orderHistoryFilterProvider.notifier);
      notifier.setDateFilter(OrderDateFilter.allTime);
      notifier.setPaymentMethod(PaymentMethodType.kpay);

      final filtered = container.read(filteredOrderHistoryProvider);
      expect(filtered.every((s) => s.paymentMethod == PaymentMethodType.kpay), isTrue);
      expect(filtered.length, 1);
      expect(filtered.first.receiptNo, 'SP-20261013-1002');
    });

    test('Search query matches voucher number or customer name', () {
      final notifier = container.read(orderHistoryFilterProvider.notifier);
      notifier.setDateFilter(OrderDateFilter.allTime);
      notifier.setSearchQuery('Ko Kyaw Swar');

      final filtered = container.read(filteredOrderHistoryProvider);
      expect(filtered.length, 1);
      expect(filtered.first.customerName, 'Ko Kyaw Swar');
    });

    test('Summary calculations compute accurate today revenue breakdowns', () {
      // By default filter is Today
      final summary = container.read(orderHistorySummaryProvider);
      expect(summary.orderCount, 3);
      // 1001: 70,000 Ks (Cash)
      // 1002: 41,500 Ks (KPay)
      // 1003: 45,000 Ks (WavePay)
      // Total: 156,500 Ks
      expect(summary.totalRevenue, 156500.0);
      expect(summary.cashRevenue, 70000.0);
      expect(summary.digitalRevenue, 86500.0);
      expect(summary.creditRevenue, 0.0);
    });
  });
}
