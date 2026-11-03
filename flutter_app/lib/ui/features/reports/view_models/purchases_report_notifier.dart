// ============================================================
// Purchases Report ViewModels & Riverpod Providers
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../purchases/view_models/purchase_notifier.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../../settings/view_models/category_notifier.dart';

enum PurchasesReportDateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  allTime,
  custom,
}

extension PurchasesReportDateFilterX on PurchasesReportDateFilter {
  String get label => switch (this) {
        PurchasesReportDateFilter.today => 'Today (ယနေ့)',
        PurchasesReportDateFilter.yesterday => 'Yesterday (မနေ့က)',
        PurchasesReportDateFilter.thisWeek => 'This Week (ဒီအပတ်)',
        PurchasesReportDateFilter.thisMonth => 'This Month (ဒီလ)',
        PurchasesReportDateFilter.allTime => 'All Time (အားလုံး)',
        PurchasesReportDateFilter.custom => 'Custom Range...',
      };
}

class PurchasesReportFilterState {
  const PurchasesReportFilterState({
    this.dateFilter = PurchasesReportDateFilter.allTime,
    this.customStartDate,
    this.customEndDate,
    this.branchId = 'all',
    this.paymentStatus = 'all', // 'all', 'paid', 'unpaid', 'partial'
    this.vendorId = 'all',
    this.searchQuery = '',
  });

  final PurchasesReportDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String branchId;
  final String paymentStatus;
  final String vendorId;
  final String searchQuery;

  PurchasesReportFilterState copyWith({
    PurchasesReportDateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? branchId,
    String? paymentStatus,
    String? vendorId,
    String? searchQuery,
  }) {
    return PurchasesReportFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      branchId: branchId ?? this.branchId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      vendorId: vendorId ?? this.vendorId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PurchasesReportFilterNotifier
    extends Notifier<PurchasesReportFilterState> {
  @override
  PurchasesReportFilterState build() => const PurchasesReportFilterState();

  void setDateFilter(PurchasesReportDateFilter filter) =>
      state = state.copyWith(dateFilter: filter);

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      dateFilter: PurchasesReportDateFilter.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setBranch(String branchId) =>
      state = state.copyWith(branchId: branchId);

  void setPaymentStatus(String status) =>
      state = state.copyWith(paymentStatus: status);

  void setVendor(String vendorId) =>
      state = state.copyWith(vendorId: vendorId);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void resetFilters() => state = const PurchasesReportFilterState();
}

final purchasesReportFilterProvider = NotifierProvider<
    PurchasesReportFilterNotifier, PurchasesReportFilterState>(
  PurchasesReportFilterNotifier.new,
);

/// Summary per vendor
class VendorPurchasesSummary {
  const VendorPurchasesSummary({
    required this.vendorId,
    required this.vendorName,
    this.phone,
    required this.invoiceCount,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalOutstanding,
  });

  final String vendorId;
  final String vendorName;
  final String? phone;
  final int invoiceCount;
  final double totalPurchased;
  final double totalPaid;
  final double totalOutstanding;

  double get paidPercentage =>
      totalPurchased > 0 ? (totalPaid / totalPurchased) * 100 : 0.0;
}

/// Summary per category
class CategoryPurchasesSummary {
  const CategoryPurchasesSummary({
    required this.category,
    required this.categoryName,
    required this.totalAmount,
    required this.totalQuantity,
    required this.percentageShare,
  });

  final ProductCategory category;
  final String categoryName;
  final double totalAmount;
  final double totalQuantity;
  final double percentageShare;
}

/// Aggregated report data model
class PurchasesReportData {
  const PurchasesReportData({
    required this.purchases,
    required this.totalPurchases,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalInvoices,
    required this.totalItemsCount,
    required this.vendorSummaries,
    required this.categorySummaries,
  });

  final List<Purchase> purchases;
  final double totalPurchases;
  final double totalPaid;
  final double totalOutstanding;
  final int totalInvoices;
  final double totalItemsCount;
  final List<VendorPurchasesSummary> vendorSummaries;
  final List<CategoryPurchasesSummary> categorySummaries;

  double get paidPercentage =>
      totalPurchases > 0 ? (totalPaid / totalPurchases) * 100 : 0.0;
}

/// Provider computing full Purchases report metrics from active filter & purchases
final purchasesReportDataProvider = Provider<PurchasesReportData>((ref) {
  final filter = ref.watch(purchasesReportFilterProvider);
  final purchaseState = ref.watch(purchaseProvider);
  final vendors = ref.watch(vendorProvider);

  final allPurchases = purchaseState.purchases;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

  final filtered = allPurchases.where((p) {
    // 1. Branch filter
    if (filter.branchId != 'all' && p.branchId != filter.branchId) {
      return false;
    }

    // 2. Payment status filter
    if (filter.paymentStatus != 'all') {
      final statusStr = p.paymentStatus.name;
      if (statusStr != filter.paymentStatus) return false;
    }

    // 3. Vendor filter
    if (filter.vendorId != 'all') {
      if (p.vendorId != filter.vendorId) return false;
    }

    // 4. Search query
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.toLowerCase().trim();
      final matchNo = p.purchaseNo.toLowerCase().contains(q);
      final matchVendor = p.vendorName?.toLowerCase().contains(q) ?? false;
      final matchNotes = p.notes?.toLowerCase().contains(q) ?? false;
      final matchItem =
          p.items.any((i) => i.productName.toLowerCase().contains(q));
      if (!matchNo && !matchVendor && !matchNotes && !matchItem) return false;
    }

    // 5. Date filter
    final date = p.purchaseDate;
    switch (filter.dateFilter) {
      case PurchasesReportDateFilter.today:
        return date.isAfter(startOfToday) ||
            (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day);
      case PurchasesReportDateFilter.yesterday:
        return date.isAfter(startOfYesterday) && date.isBefore(startOfToday);
      case PurchasesReportDateFilter.thisWeek:
        return now.difference(date).inDays <= 7;
      case PurchasesReportDateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;
      case PurchasesReportDateFilter.allTime:
        return true;
      case PurchasesReportDateFilter.custom:
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
          return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              date.isBefore(end.add(const Duration(seconds: 1)));
        }
        return true;
    }
  }).toList();

  // Sort newest first
  filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

  // Compute KPI totals
  double totalPurchases = 0;
  double totalPaid = 0;
  double totalOutstanding = 0;
  double totalItems = 0;

  for (final p in filtered) {
    totalPurchases += p.totalAmount;
    totalPaid += p.paidAmount;
    totalOutstanding += p.balanceDue;
    for (final item in p.items) {
      totalItems += item.quantity;
    }
  }

  // Vendor map for lookup
  final vendorPhoneMap = {
    for (final v in vendors) v.id: v.phone,
  };

  // Group by Vendor
  final Map<String, List<Purchase>> vendorGroups = {};
  for (final p in filtered) {
    final vKey = p.vendorId ?? (p.vendorName ?? 'unassigned');
    vendorGroups.putIfAbsent(vKey, () => []).add(p);
  }

  final List<VendorPurchasesSummary> vendorSummaries = [];
  vendorGroups.forEach((vKey, pList) {
    double vPurchased = 0;
    double vPaid = 0;
    double vDue = 0;
    String vName = pList.first.vendorName ?? 'အမည်မသိ ကုန်သည်';
    String? phone = vendorPhoneMap[pList.first.vendorId];

    for (final p in pList) {
      vPurchased += p.totalAmount;
      vPaid += p.paidAmount;
      vDue += p.balanceDue;
    }

    vendorSummaries.add(
      VendorPurchasesSummary(
        vendorId: vKey,
        vendorName: vName,
        phone: phone,
        invoiceCount: pList.length,
        totalPurchased: vPurchased,
        totalPaid: vPaid,
        totalOutstanding: vDue,
      ),
    );
  });
  // Sort vendors by total purchase amount descending
  vendorSummaries.sort((a, b) => b.totalPurchased.compareTo(a.totalPurchased));

  // Category breakdown (dynamic from backend categories & catalog)
  final catalog = ref.watch(catalogProvider);
  final activeCategories = ref.watch(categoryNotifierProvider);
  final productById = {for (final p in catalog) p.id: p};

  final Map<String, ({ProductCategory stdCat, String displayName, double amount, double quantity})> catMap = {};
  for (final catItem in activeCategories) {
    final label = catItem.englishName.isNotEmpty &&
            catItem.englishName.toLowerCase() != catItem.name.toLowerCase()
        ? '${catItem.englishName} (${catItem.name})'
        : catItem.name;
    catMap[catItem.id] = (
      stdCat: catItem.standardCategory ?? ProductCategory.others,
      displayName: label,
      amount: 0.0,
      quantity: 0.0,
    );
  }

  for (final p in filtered) {
    for (final item in p.items) {
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
      }
      final fallbackCat = prod?.category ?? ProductCategory.plants;
      matchedKey ??= fallbackCat.name;
      final cur = catMap[matchedKey] ??
          (
            stdCat: fallbackCat,
            displayName: prod?.categoryName ?? fallbackCat.name,
            amount: 0.0,
            quantity: 0.0,
          );
      catMap[matchedKey] = (
        stdCat: cur.stdCat,
        displayName: cur.displayName,
        amount: cur.amount + item.totalCost,
        quantity: cur.quantity + item.quantity,
      );
    }
  }

  final List<CategoryPurchasesSummary> categorySummaries = [];
  catMap.forEach((_, data) {
    if (data.amount > 0 || data.quantity > 0) {
      final share =
          totalPurchases > 0 ? (data.amount / totalPurchases) * 100 : 0.0;
      categorySummaries.add(
        CategoryPurchasesSummary(
          category: data.stdCat,
          categoryName: data.displayName,
          totalAmount: data.amount,
          totalQuantity: data.quantity,
          percentageShare: share,
        ),
      );
    }
  });
  categorySummaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

  return PurchasesReportData(
    purchases: filtered,
    totalPurchases: totalPurchases,
    totalPaid: totalPaid,
    totalOutstanding: totalOutstanding,
    totalInvoices: filtered.length,
    totalItemsCount: totalItems,
    vendorSummaries: vendorSummaries,
    categorySummaries: categorySummaries,
  );
});
