import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../wastage/view_models/wastage_notifier.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../hr_payroll/view_models/payroll_notifier.dart';
import '../../settings/view_models/category_notifier.dart';

enum ReportPeriod {
  today,
  last7Days,
  thisMonth,
  allTime,
}

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.today => 'ယနေ့ (Today)',
        ReportPeriod.last7Days => '၇ ရက် (Last 7 Days)',
        ReportPeriod.thisMonth => 'ဒီလ (This Month)',
        ReportPeriod.allTime => 'အားလုံး (All Time)',
      };
}

class SalesSummary {
  const SalesSummary({
    required this.grossRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.grossMargin,
    required this.orderCount,
    required this.unitsCount,
    required this.averageOrderValue,
  });

  final double grossRevenue;
  final double totalCost;
  final double grossProfit;
  final double grossMargin; // Percentage 0 - 100
  final int orderCount;
  final int unitsCount;
  final double averageOrderValue;
}

class CategorySalesSummary {
  const CategorySalesSummary({
    required this.category,
    required this.categoryName,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.unitsSold,
    required this.revenueShare,
  });

  final ProductCategory category;
  final String categoryName;
  final double revenue;
  final double cost;
  final double profit;
  final double margin; // 0 - 100
  final int unitsSold;
  final double revenueShare; // 0 - 100
}

class WastageReportSummary {
  const WastageReportSummary({
    required this.totalLoss,
    required this.totalQuantity,
    required this.lossByReason,
  });

  final double totalLoss;
  final int totalQuantity;
  final Map<WastageReasonOption, double> lossByReason;
}

class ReportsFilterState {
  const ReportsFilterState({
    this.period = ReportPeriod.last7Days,
    this.branchId = 'all',
  });

  final ReportPeriod period;
  final String branchId;

  ReportsFilterState copyWith({
    ReportPeriod? period,
    String? branchId,
  }) {
    return ReportsFilterState(
      period: period ?? this.period,
      branchId: branchId ?? this.branchId,
    );
  }
}

class ReportsFilterNotifier extends Notifier<ReportsFilterState> {
  @override
  ReportsFilterState build() => const ReportsFilterState();

  void setPeriod(ReportPeriod period) => state = state.copyWith(period: period);
  void setBranch(String branchId) => state = state.copyWith(branchId: branchId);
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportsFilterState>(
        ReportsFilterNotifier.new);

/// Aggregated reports analytics provider
final reportsDataProvider = Provider<ReportsDashboardData>((ref) {
  final filter = ref.watch(reportsFilterProvider);
  final wastageState = ref.watch(wastageProvider);
  final catalog = ref.watch(catalogProvider);

  final productCostMap = {
    for (final p in catalog) p.id: p.costPrice,
  };

  // Combine live sales transactions from database and current POS session
  final allSales = ref.watch(allTransactionsProvider);

  // 1. Date & Branch filtering for sales
  final now = DateTime.now();
  final filteredSales = allSales.where((s) {
    if (filter.branchId != 'all' && s.branchId != filter.branchId) {
      return false;
    }
    final diff = now.difference(s.createdAt);
    return switch (filter.period) {
      ReportPeriod.today => diff.inDays == 0 && s.createdAt.day == now.day,
      ReportPeriod.last7Days => diff.inDays <= 7,
      ReportPeriod.thisMonth => diff.inDays <= 30 && s.createdAt.month == now.month,
      ReportPeriod.allTime => true,
    };
  }).toList();

  // 2. Sales Summary computation
  double grossRevenue = 0;
  double totalCost = 0;
  int unitsCount = 0;

  for (final sale in filteredSales) {
    grossRevenue += sale.totalAmount;
    for (final item in sale.items) {
      unitsCount += item.quantity;
      final unitCost = productCostMap[item.productId] ?? (item.unitPrice * 0.6);
      totalCost += unitCost * item.quantity;
    }
  }

  final grossProfit = grossRevenue - totalCost;
  final grossMargin = grossRevenue > 0 ? (grossProfit / grossRevenue) * 100 : 0.0;
  final orderCount = filteredSales.length;
  final aov = orderCount > 0 ? grossRevenue / orderCount : 0.0;

  final salesSummary = SalesSummary(
    grossRevenue: grossRevenue,
    totalCost: totalCost,
    grossProfit: grossProfit,
    grossMargin: grossMargin,
    orderCount: orderCount,
    unitsCount: unitsCount,
    averageOrderValue: aov,
  );

  // 3. Category Breakdown computation (dynamic from backend categories & catalog)
  final activeCategories = ref.watch(categoryNotifierProvider);
  final productById = {for (final p in catalog) p.id: p};

  final Map<String, ({ProductCategory stdCat, String displayName, double revenue, double cost, int units})> catAgg = {};
  for (final catItem in activeCategories) {
    final label = catItem.englishName.isNotEmpty &&
            catItem.englishName.toLowerCase() != catItem.name.toLowerCase()
        ? '${catItem.englishName} (${catItem.name})'
        : catItem.name;
    catAgg[catItem.id] = (
      stdCat: catItem.standardCategory ?? ProductCategory.others,
      displayName: label,
      revenue: 0.0,
      cost: 0.0,
      units: 0,
    );
  }

  for (final sale in filteredSales) {
    for (final item in sale.items) {
      final prod = productById[item.productId];
      String? matchedKey;
      for (final catItem in activeCategories) {
        if (prod != null &&
            prod.matchesCategory(
              selectedCategoryId: catItem.id,
              standardCategory: catItem.standardCategory,
              catName: catItem.name,
              catEnglishName: catItem.englishName,
            )) {
          matchedKey = catItem.id;
          break;
        }
        if (prod == null && catItem.standardCategory == item.category) {
          matchedKey = catItem.id;
          break;
        }
      }
      matchedKey ??= item.category.name;
      final current = catAgg[matchedKey] ??
          (
            stdCat: item.category,
            displayName: prod?.categoryName ?? item.category.name,
            revenue: 0.0,
            cost: 0.0,
            units: 0,
          );
      final unitCost = productCostMap[item.productId] ?? (item.unitPrice * 0.6);
      catAgg[matchedKey] = (
        stdCat: current.stdCat,
        displayName: current.displayName,
        revenue: current.revenue + item.lineTotal,
        cost: current.cost + (unitCost * item.quantity),
        units: current.units + item.quantity,
      );
    }
  }

  final List<CategorySalesSummary> categorySummaries = [];
  for (final entry in catAgg.entries) {
    final data = entry.value;
    final catProfit = data.revenue - data.cost;
    final catMargin = data.revenue > 0 ? (catProfit / data.revenue) * 100 : 0.0;
    final catShare = grossRevenue > 0 ? (data.revenue / grossRevenue) * 100 : 0.0;

    categorySummaries.add(CategorySalesSummary(
      category: data.stdCat,
      categoryName: data.displayName,
      revenue: data.revenue,
      cost: data.cost,
      profit: catProfit,
      margin: catMargin,
      unitsSold: data.units,
      revenueShare: catShare,
    ));
  }

  // Sort categories by revenue descending
  categorySummaries.sort((a, b) => b.revenue.compareTo(a.revenue));

  // 4. Wastage & Mortality Loss computation
  final filteredWastage = wastageState.entries.where((w) {
    if (filter.branchId != 'all' && w.branchId != filter.branchId) {
      return false;
    }
    final diff = now.difference(w.recordedAt);
    return switch (filter.period) {
      ReportPeriod.today => diff.inDays == 0 && w.recordedAt.day == now.day,
      ReportPeriod.last7Days => diff.inDays <= 7,
      ReportPeriod.thisMonth => diff.inDays <= 30 && w.recordedAt.month == now.month,
      ReportPeriod.allTime => true,
    };
  }).toList();

  double totalWastageLoss = 0;
  int totalWastageUnits = 0;
  final Map<WastageReasonOption, double> lossByReason = {
    for (final r in WastageReasonOption.values) r: 0.0,
  };

  for (final w in filteredWastage) {
    totalWastageLoss += w.totalCostLoss;
    totalWastageUnits += w.quantity;
    lossByReason[w.reason] = (lossByReason[w.reason] ?? 0.0) + w.totalCostLoss;
  }

  final wastageSummary = WastageReportSummary(
    totalLoss: totalWastageLoss,
    totalQuantity: totalWastageUnits,
    lossByReason: lossByReason,
  );

  // 5. Operating Expenses (OPEX - Paid Salaries / Payroll)
  final payrollList = ref.watch(payrollProvider);
  final filteredPayrolls = payrollList.where((p) {
    if (filter.branchId != 'all' && p.branchId != filter.branchId) {
      return false;
    }
    final diff = now.difference(p.paymentDate);
    return switch (filter.period) {
      ReportPeriod.today => diff.inDays == 0 && p.paymentDate.day == now.day,
      ReportPeriod.last7Days => diff.inDays <= 7,
      ReportPeriod.thisMonth => diff.inDays <= 30 && p.paymentDate.month == now.month,
      ReportPeriod.allTime => true,
    };
  }).toList();

  double totalOperatingExpense = 0;
  for (final p in filteredPayrolls) {
    totalOperatingExpense += p.netSalary;
  }

  // 6. Net Profit = Gross Profit - Wastage Loss - Operating Expenses (Salaries)
  final netProfit = grossProfit - totalWastageLoss - totalOperatingExpense;
  final netMargin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0.0;

  return ReportsDashboardData(
    filter: filter,
    salesSummary: salesSummary,
    categorySummaries: categorySummaries,
    wastageSummary: wastageSummary,
    operatingExpense: totalOperatingExpense,
    payrollDisbursedCount: filteredPayrolls.length,
    netProfit: netProfit,
    netMargin: netMargin,
  );
});

class ReportsDashboardData {
  const ReportsDashboardData({
    required this.filter,
    required this.salesSummary,
    required this.categorySummaries,
    required this.wastageSummary,
    required this.operatingExpense,
    required this.payrollDisbursedCount,
    required this.netProfit,
    required this.netMargin,
  });

  final ReportsFilterState filter;
  final SalesSummary salesSummary;
  final List<CategorySalesSummary> categorySummaries;
  final WastageReportSummary wastageSummary;
  final double operatingExpense;
  final int payrollDisbursedCount;
  final double netProfit;
  final double netMargin;
}
