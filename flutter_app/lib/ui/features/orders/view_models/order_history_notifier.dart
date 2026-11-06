import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../data/repositories/sale_repository.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../pos/view_models/transaction_notifier.dart';

enum OrderDateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  allTime,
  custom,
}

extension OrderDateFilterX on OrderDateFilter {
  String get label => switch (this) {
        OrderDateFilter.today => 'Today (ယနေ့)',
        OrderDateFilter.yesterday => 'Yesterday (မနေ့က)',
        OrderDateFilter.thisWeek => 'This Week (ဒီအပတ်)',
        OrderDateFilter.thisMonth => 'This Month (ဒီလ)',
        OrderDateFilter.allTime => 'All Time (အားလုံး)',
        OrderDateFilter.custom => 'Custom Date (စိတ်ကြိုက်ရက်စွဲ)',
      };
}

class OrderHistoryFilterState {
  const OrderHistoryFilterState({
    this.dateFilter = OrderDateFilter.today, // REQUIRED: Defaults to today
    this.customDateRange,
    this.branchId = 'all',
    this.paymentMethod,
    this.searchQuery = '',
  });

  final OrderDateFilter dateFilter;
  final DateTimeRange? customDateRange;
  final String branchId;
  final PaymentMethodType? paymentMethod;
  final String searchQuery;

  OrderHistoryFilterState copyWith({
    OrderDateFilter? dateFilter,
    DateTimeRange? customDateRange,
    bool clearCustomDate = false,
    String? branchId,
    PaymentMethodType? paymentMethod,
    bool clearPaymentMethod = false,
    String? searchQuery,
  }) {
    return OrderHistoryFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customDateRange:
          clearCustomDate ? null : (customDateRange ?? this.customDateRange),
      branchId: branchId ?? this.branchId,
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrderHistoryFilterNotifier extends Notifier<OrderHistoryFilterState> {
  @override
  OrderHistoryFilterState build() {
    final defaultBranch = ref.watch(defaultBranchProvider);
    return OrderHistoryFilterState(branchId: defaultBranch);
  }

  void setDateFilter(OrderDateFilter filter) {
    state = state.copyWith(
      dateFilter: filter,
      clearCustomDate: filter != OrderDateFilter.custom,
    );
  }

  void setCustomDateRange(DateTimeRange range) {
    state = state.copyWith(
      dateFilter: OrderDateFilter.custom,
      customDateRange: range,
    );
  }

  void setBranch(String branchId) {
    state = state.copyWith(branchId: branchId);
  }

  void setPaymentMethod(PaymentMethodType? method) {
    state = state.copyWith(
      paymentMethod: method,
      clearPaymentMethod: method == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void resetFilters() {
    final defaultBranch = ref.read(defaultBranchProvider);
    state = OrderHistoryFilterState(branchId: defaultBranch);
  }
}

final orderHistoryFilterProvider =
    NotifierProvider<OrderHistoryFilterNotifier, OrderHistoryFilterState>(
  OrderHistoryFilterNotifier.new,
);

final remoteSalesProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSales();
});

/// Aggregated transactions: server database records combined with live in-flight transactions (LIFO)
final allTransactionsProvider = Provider<List<SaleTransaction>>((ref) {
  final txState = ref.watch(transactionProvider);
  final remoteSales = ref.watch(remoteSalesProvider).valueOrNull ?? [];
  final remoteReceiptNos = remoteSales.map((t) => t.receiptNo).toSet();
  final unsyncedLocal = txState.transactions
      .where((t) => !remoteReceiptNos.contains(t.receiptNo))
      .toList();
  final combined = [...unsyncedLocal, ...remoteSales];
  combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return combined;
});

/// Filtered transactions based on current user filter selections
final filteredOrderHistoryProvider = Provider<List<SaleTransaction>>((ref) {
  final allSales = ref.watch(allTransactionsProvider);
  final filter = ref.watch(orderHistoryFilterProvider);

  final now = DateTime.now();
  final latestSaleDate = allSales.isNotEmpty
      ? allSales.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
      : now;
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));

  return allSales.where((sale) {
    // 1. Branch filter
    if (filter.branchId != 'all' && sale.branchId != filter.branchId) {
      return false;
    }

    // 2. Payment method filter
    if (filter.paymentMethod != null && sale.paymentMethod != filter.paymentMethod) {
      return false;
    }

    // 3. Search query filter (receiptNo, customer, phone, item name)
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchReceipt = sale.receiptNo.toLowerCase().contains(q);
      final matchCustomer =
          sale.customerName?.toLowerCase().contains(q) ?? false;
      final matchPhone = sale.customerPhone?.contains(q) ?? false;
      final matchItems = sale.items
          .any((item) => item.productName.toLowerCase().contains(q));

      if (!matchReceipt && !matchCustomer && !matchPhone && !matchItems) {
        return false;
      }
    }

    // 4. Date filter (Default: Today — handles both device clock and backend server clock)
    final saleDate = sale.createdAt;
    switch (filter.dateFilter) {
      case OrderDateFilter.today:
        final matchesDeviceToday = saleDate.year == now.year &&
            saleDate.month == now.month &&
            saleDate.day == now.day;
        final matchesLatestServerToday = saleDate.year == latestSaleDate.year &&
            saleDate.month == latestSaleDate.month &&
            saleDate.day == latestSaleDate.day;
        return matchesDeviceToday || matchesLatestServerToday;

      case OrderDateFilter.yesterday:
        return saleDate.year == yesterdayStart.year &&
            saleDate.month == yesterdayStart.month &&
            saleDate.day == yesterdayStart.day;

      case OrderDateFilter.thisWeek:
        return now.difference(saleDate).inDays <= 7;

      case OrderDateFilter.thisMonth:
        return saleDate.year == now.year && saleDate.month == now.month;

      case OrderDateFilter.allTime:
        return true;

      case OrderDateFilter.custom:
        if (filter.customDateRange == null) return true;
        final start = DateTime(
          filter.customDateRange!.start.year,
          filter.customDateRange!.start.month,
          filter.customDateRange!.start.day,
        );
        final end = DateTime(
          filter.customDateRange!.end.year,
          filter.customDateRange!.end.month,
          filter.customDateRange!.end.day,
          23,
          59,
          59,
        );
        return saleDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            saleDate.isBefore(end.add(const Duration(seconds: 1)));
    }
  }).toList();
});

/// Metrics Summary for the currently active filter
class OrderHistorySummary {
  const OrderHistorySummary({
    required this.orderCount,
    required this.totalRevenue,
    required this.cashRevenue,
    required this.digitalRevenue,
    required this.creditRevenue,
  });

  final int orderCount;
  final double totalRevenue;
  final double cashRevenue;
  final double digitalRevenue;
  final double creditRevenue;
}

final orderHistorySummaryProvider = Provider<OrderHistorySummary>((ref) {
  final orders = ref.watch(filteredOrderHistoryProvider);

  double totalRevenue = 0;
  double cashRevenue = 0;
  double digitalRevenue = 0;
  double creditRevenue = 0;

  for (final sale in orders) {
    totalRevenue += sale.totalAmount;
    if (sale.isCash) {
      cashRevenue += sale.totalAmount;
    } else if (sale.isDigital) {
      digitalRevenue += sale.totalAmount;
    } else if (sale.isCredit) {
      creditRevenue += sale.totalAmount;
    }
  }

  return OrderHistorySummary(
    orderCount: orders.length,
    totalRevenue: totalRevenue,
    cashRevenue: cashRevenue,
    digitalRevenue: digitalRevenue,
    creditRevenue: creditRevenue,
  );
});
