import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../settings/view_models/category_notifier.dart';

class StockValuationItem {
  const StockValuationItem({
    required this.product,
    required this.branchAStock,
    required this.branchBStock,
    required this.totalStock,
    required this.unitCost,
    required this.unitPrice,
    required this.totalCostValue,
    required this.potentialRetailValue,
  });

  final MockProduct product;
  final int branchAStock;
  final int branchBStock;
  final int totalStock;
  final double unitCost;
  final double unitPrice;
  final double totalCostValue;
  final double potentialRetailValue;

  double get potentialGrossProfit => potentialRetailValue - totalCostValue;
}

class StockValuationSummary {
  const StockValuationSummary({
    required this.totalSkus,
    required this.totalUnits,
    required this.totalCostValue,
    required this.potentialRetailValue,
    required this.items,
  });

  final int totalSkus;
  final int totalUnits;
  final double totalCostValue;
  final double potentialRetailValue;
  final List<StockValuationItem> items;
}

class StockValuationFilterState {
  const StockValuationFilterState({
    this.searchQuery = '',
    this.category = ProductCategory.all,
    this.categoryId = 'all',
  });

  final String searchQuery;
  final ProductCategory category;
  final String categoryId;

  StockValuationFilterState copyWith({
    String? searchQuery,
    ProductCategory? category,
    String? categoryId,
  }) {
    return StockValuationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class StockValuationFilterNotifier
    extends Notifier<StockValuationFilterState> {
  @override
  StockValuationFilterState build() => const StockValuationFilterState();

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);
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
}

final stockValuationFilterProvider =
    NotifierProvider<StockValuationFilterNotifier, StockValuationFilterState>(
        StockValuationFilterNotifier.new);

final stockValuationReportProvider = Provider<StockValuationSummary>((ref) {
  final catalog = ref.watch(catalogProvider);
  final inventory = ref.watch(inventoryProvider);
  final filter = ref.watch(stockValuationFilterProvider);
  final categories = ref.watch(categoryNotifierProvider);

  final selectedCatItem = filter.categoryId == 'all'
      ? null
      : categories.where((c) => c.id == filter.categoryId).firstOrNull;

  final List<StockValuationItem> allItems = [];

  for (final product in catalog) {
    final aStock = inventory.getStock('branch_a', product.id);
    final bStock = inventory.getStock('branch_b', product.id);
    final totStock = aStock + bStock;
    final cost = product.costPrice > 0 ? product.costPrice : (product.salePrice * 0.6);
    final price = product.salePrice;
    final costVal = totStock * cost;
    final retailVal = totStock * price;

    allItems.add(StockValuationItem(
      product: product,
      branchAStock: aStock,
      branchBStock: bStock,
      totalStock: totStock,
      unitCost: cost,
      unitPrice: price,
      totalCostValue: costVal,
      potentialRetailValue: retailVal,
    ));
  }

  // Filter
  final filteredItems = allItems.where((item) {
    if (filter.categoryId != 'all') {
      final matched = item.product.matchesCategory(
        selectedCategoryId: filter.categoryId,
        standardCategory: selectedCatItem?.standardCategory ??
            (filter.category != ProductCategory.all ? filter.category : null),
        catName: selectedCatItem?.name,
        catEnglishName: selectedCatItem?.englishName,
      );
      if (!matched) return false;
    } else if (filter.category != ProductCategory.all &&
        item.product.category != filter.category) {
      return false;
    }
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final nameMatch = item.product.name.toLowerCase().contains(q);
      final skuMatch = item.product.sku.toLowerCase().contains(q);
      final barcodeMatch =
          item.product.barcode?.toLowerCase().contains(q) ?? false;
      if (!nameMatch && !skuMatch && !barcodeMatch) return false;
    }
    return true;
  }).toList();

  final totalUnits =
      filteredItems.fold(0, (acc, item) => acc + item.totalStock);
  final totalCostValue =
      filteredItems.fold(0.0, (acc, item) => acc + item.totalCostValue);
  final potentialRetailValue =
      filteredItems.fold(0.0, (acc, item) => acc + item.potentialRetailValue);

  return StockValuationSummary(
    totalSkus: filteredItems.length,
    totalUnits: totalUnits,
    totalCostValue: totalCostValue,
    potentialRetailValue: potentialRetailValue,
    items: filteredItems,
  );
});
