import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../settings/view_models/category_notifier.dart';

enum ProductSalesSortBy {
  highestVolume,
  highestRevenue,
  highestMargin,
}

extension ProductSalesSortByX on ProductSalesSortBy {
  String get label => switch (this) {
        ProductSalesSortBy.highestVolume => 'Highest Volume (အရောင်းပမာဏအများဆုံး)',
        ProductSalesSortBy.highestRevenue => 'Highest Revenue (ရငွေအများဆုံး)',
        ProductSalesSortBy.highestMargin => 'Highest Margin (အမြတ်ရာခိုင်နှုန်းအများဆုံး)',
      };
}

class ProductWiseSaleSummary {
  const ProductWiseSaleSummary({
    required this.productId,
    required this.productName,
    required this.category,
    this.categoryId,
    this.categoryName,
    this.originType,
    required this.unitPrice,
    required this.unitCost,
    required this.soldQuantity,
    required this.costTotal,
    required this.revenueTotal,
    required this.grossProfit,
    required this.grossMarginPercent,
  });

  final String productId;
  final String productName;
  final ProductCategory category;
  final String? categoryId;
  final String? categoryName;
  final OriginType? originType;
  final double unitPrice;
  final double unitCost;
  final int soldQuantity;
  final double costTotal;
  final double revenueTotal;
  final double grossProfit;
  final double grossMarginPercent;
}

class ProductSalesReportFilter {
  const ProductSalesReportFilter({
    this.category = ProductCategory.all,
    this.categoryId = 'all',
    this.originFilter = 'all', // 'all', 'thaiImport', 'chinaImport', 'local'
    this.sortBy = ProductSalesSortBy.highestRevenue,
    this.searchQuery = '',
  });

  final ProductCategory category;
  final String categoryId;
  final String originFilter;
  final ProductSalesSortBy sortBy;
  final String searchQuery;

  ProductSalesReportFilter copyWith({
    ProductCategory? category,
    String? categoryId,
    String? originFilter,
    ProductSalesSortBy? sortBy,
    String? searchQuery,
  }) {
    return ProductSalesReportFilter(
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      originFilter: originFilter ?? this.originFilter,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductSalesReportNotifier extends Notifier<ProductSalesReportFilter> {
  @override
  ProductSalesReportFilter build() => const ProductSalesReportFilter();

  void setCategory(ProductCategory cat) => state = state.copyWith(
        category: cat,
        categoryId: cat == ProductCategory.all ? 'all' : cat.name,
      );

  void setCategoryId(String id, {ProductCategory? stdCategory}) =>
      state = state.copyWith(
        categoryId: id,
        category: id == 'all'
            ? ProductCategory.all
            : (stdCategory ?? ProductCategory.others),
      );

  void setOrigin(String origin) =>
      state = state.copyWith(originFilter: origin);

  void setSortBy(ProductSalesSortBy sortBy) =>
      state = state.copyWith(sortBy: sortBy);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
}

final productSalesReportFilterProvider =
    NotifierProvider<ProductSalesReportNotifier, ProductSalesReportFilter>(
        ProductSalesReportNotifier.new);

/// Computed provider for aggregated product-wise sales summaries
final productWiseSalesDataProvider = Provider<List<ProductWiseSaleSummary>>((ref) {
  final filter = ref.watch(productSalesReportFilterProvider);
  final catalog = ref.watch(catalogProvider);
  final allSales = ref.watch(allTransactionsProvider);
  final categories = ref.watch(categoryNotifierProvider);

  final selectedCatItem = filter.categoryId == 'all'
      ? null
      : categories.where((c) => c.id == filter.categoryId).firstOrNull;

  // Map product id to aggregated stats: quantity, revenue, and historical cost
  final Map<String, ({int quantity, double revenue, double cost})> aggMap = {};

  for (final sale in allSales) {
    for (final item in sale.items) {
      final current = aggMap[item.productId] ?? (quantity: 0, revenue: 0.0, cost: 0.0);
      final itemUnitCost = item.unitCost > 0
          ? item.unitCost
          : (catalog.where((c) => c.id == item.productId).firstOrNull?.costPrice ??
              (item.unitPrice * 0.6));
      final lineCost = itemUnitCost * item.quantity;

      aggMap[item.productId] = (
        quantity: current.quantity + item.quantity,
        revenue: current.revenue + item.lineTotal,
        cost: current.cost + lineCost,
      );
    }
  }

  // Build full summaries for every sold product (plus products in catalog that have sales)
  final List<ProductWiseSaleSummary> summaries = [];

  for (final p in catalog) {
    final agg = aggMap[p.id];
    final soldQty = agg?.quantity ?? 0;
    final rev = agg?.revenue ?? 0.0;
    final totalCost = agg?.cost ?? 0.0;
    final profit = rev - totalCost;
    final marginPct = rev > 0 ? (profit / rev) * 100 : 0.0;

    final avgUnitPrice = soldQty > 0 ? (rev / soldQty) : p.salePrice;
    final avgUnitCost = soldQty > 0 ? (totalCost / soldQty) : p.costPrice;

    summaries.add(ProductWiseSaleSummary(
      productId: p.id,
      productName: p.name,
      category: p.category,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      originType: p.originType,
      unitPrice: avgUnitPrice,
      unitCost: avgUnitCost,
      soldQuantity: soldQty,
      costTotal: totalCost,
      revenueTotal: rev,
      grossProfit: profit,
      grossMarginPercent: marginPct,
    ));
  }

  // Filter by category
  var filtered = summaries.where((s) {
    if (filter.categoryId != 'all') {
      final matchedProd = catalog.where((c) => c.id == s.productId).firstOrNull;
      if (matchedProd != null) {
        final matched = matchedProd.matchesCategory(
          selectedCategoryId: filter.categoryId,
          standardCategory: selectedCatItem?.standardCategory ??
              (filter.category != ProductCategory.all ? filter.category : null),
          catName: selectedCatItem?.name,
          catEnglishName: selectedCatItem?.englishName,
        );
        if (!matched) return false;
      } else if (s.category != filter.category) {
        return false;
      }
    } else if (filter.category != ProductCategory.all &&
        s.category != filter.category) {
      return false;
    }

    if (filter.originFilter != 'all') {
      if (filter.originFilter == 'thaiImport' &&
          s.originType != OriginType.thaiImport) {
        return false;
      }
      if (filter.originFilter == 'chinaImport' &&
          s.originType != OriginType.chinaImport) {
        return false;
      }
      if (filter.originFilter == 'local' &&
          s.originType != OriginType.local) {
        return false;
      }
    }

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      if (!s.productName.toLowerCase().contains(q)) return false;
    }

    return true;
  }).toList();

  // Sort
  switch (filter.sortBy) {
    case ProductSalesSortBy.highestVolume:
      filtered.sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
      break;
    case ProductSalesSortBy.highestRevenue:
      filtered.sort((a, b) => b.revenueTotal.compareTo(a.revenueTotal));
      break;
    case ProductSalesSortBy.highestMargin:
      filtered.sort((a, b) => b.grossMarginPercent.compareTo(a.grossMarginPercent));
      break;
  }

  return filtered;
});
