import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../orders/view_models/order_history_notifier.dart';

enum SalesReportDateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  allTime,
  custom,
}

extension SalesReportDateFilterX on SalesReportDateFilter {
  String get label => switch (this) {
        SalesReportDateFilter.today => 'Today (ယနေ့)',
        SalesReportDateFilter.yesterday => 'Yesterday (မနေ့က)',
        SalesReportDateFilter.thisWeek => 'This Week (ဒီအပတ်)',
        SalesReportDateFilter.thisMonth => 'This Month (ဒီလ)',
        SalesReportDateFilter.allTime => 'All Time (အားလုံး)',
        SalesReportDateFilter.custom => 'Custom Range...',
      };
}

class SalesReportFilterState {
  const SalesReportFilterState({
    this.dateFilter = SalesReportDateFilter.today,
    this.customStartDate,
    this.customEndDate,
    this.branchId = 'all',
    this.paymentMethod = 'all', // 'all', 'cash', 'kpay', 'wavePay', 'credit'
    this.searchQuery = '',
  });

  final SalesReportDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String branchId;
  final String paymentMethod;
  final String searchQuery;

  SalesReportFilterState copyWith({
    SalesReportDateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? branchId,
    String? paymentMethod,
    String? searchQuery,
  }) {
    return SalesReportFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      branchId: branchId ?? this.branchId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SalesReportFilterNotifier extends Notifier<SalesReportFilterState> {
  @override
  SalesReportFilterState build() => const SalesReportFilterState();

  void setDateFilter(SalesReportDateFilter filter) =>
      state = state.copyWith(dateFilter: filter);

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      dateFilter: SalesReportDateFilter.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setBranch(String branchId) =>
      state = state.copyWith(branchId: branchId);

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
}

final salesReportFilterProvider =
    NotifierProvider<SalesReportFilterNotifier, SalesReportFilterState>(
        SalesReportFilterNotifier.new);

class SalesTransactionsReportData {
  const SalesTransactionsReportData({
    required this.transactions,
    required this.totalCash,
    required this.totalDigital,
    required this.totalCredit,
    required this.totalNetSales,
    required this.totalOrders,
    required this.totalDiscount,
  });

  final List<SaleTransaction> transactions;
  final double totalCash;
  final double totalDigital;
  final double totalCredit;
  final double totalNetSales;
  final int totalOrders;
  final double totalDiscount;
}

final salesTransactionsReportProvider =
    Provider<SalesTransactionsReportData>((ref) {
  final filter = ref.watch(salesReportFilterProvider);
  final allTransactions = ref.watch(allTransactionsProvider);

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

  final filtered = allTransactions.where((t) {
    // 1. Branch filter
    if (filter.branchId != 'all' && t.branchId != filter.branchId) {
      return false;
    }

    // 2. Payment method filter
    if (filter.paymentMethod != 'all') {
      final methodStr = switch (t.paymentMethod) {
        PaymentMethodType.cash => 'cash',
        PaymentMethodType.kpay => 'kpay',
        PaymentMethodType.wavePay => 'wavePay',
        PaymentMethodType.mobileBanking => 'mobileBanking',
        PaymentMethodType.credit => 'credit',
      };
      if (filter.paymentMethod == 'digital') {
        if (!t.isDigital) return false;
      } else if (methodStr != filter.paymentMethod) {
        return false;
      }
    }

    // 3. Search query
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchReceipt = t.receiptNo.toLowerCase().contains(q);
      final matchCashier = t.cashierName.toLowerCase().contains(q);
      final matchItem = t.items.any((i) => i.productName.toLowerCase().contains(q));
      if (!matchReceipt && !matchCashier && !matchItem) return false;
    }

    // 4. Date filter
    final created = t.createdAt;
    switch (filter.dateFilter) {
      case SalesReportDateFilter.today:
        return created.isAfter(startOfToday) ||
            (created.year == now.year &&
                created.month == now.month &&
                created.day == now.day);
      case SalesReportDateFilter.yesterday:
        return created.isAfter(startOfYesterday) &&
            created.isBefore(startOfToday);
      case SalesReportDateFilter.thisWeek:
        return now.difference(created).inDays <= 7;
      case SalesReportDateFilter.thisMonth:
        return created.year == now.year && created.month == now.month;
      case SalesReportDateFilter.allTime:
        return true;
      case SalesReportDateFilter.custom:
        if (filter.customStartDate != null && filter.customEndDate != null) {
          final start = DateTime(
            filter.customStartDate!.year,
            filter.customStartDate!.month,
            filter.customStartDate!.day,
          );
          final end = DateTime(
            filter.customEndDate!.year,
            filter.customEndDate!.month,
            filter.customEndDate!.day,
            23,
            59,
            59,
          );
          return created.isAfter(start.subtract(const Duration(seconds: 1))) &&
              created.isBefore(end.add(const Duration(seconds: 1)));
        }
        return true;
    }
  }).toList();

  // Sort latest first
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Compute footer aggregates
  double cash = 0;
  double digital = 0;
  double credit = 0;
  double netSales = 0;
  double discount = 0;

  for (final t in filtered) {
    netSales += t.totalAmount;
    discount += t.discountAmount;
    if (t.isCash) {
      cash += t.totalAmount;
    } else if (t.isDigital) {
      digital += t.totalAmount;
    } else if (t.isCredit) {
      credit += t.totalAmount;
    }
  }

  return SalesTransactionsReportData(
    transactions: filtered,
    totalCash: cash,
    totalDigital: digital,
    totalCredit: credit,
    totalNetSales: netSales,
    totalOrders: filtered.length,
    totalDiscount: discount,
  );
});
