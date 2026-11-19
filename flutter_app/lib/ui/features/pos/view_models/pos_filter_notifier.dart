import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../../settings/view_models/plant_origin_notifier.dart';

// ============================================================
// POS Filter State
// ============================================================

class PosFilterState {
  const PosFilterState({
    this.selectedCategory   = ProductCategory.all,
    this.selectedCategoryId = 'all',
    this.selectedSubFilter  = 'All',
    this.searchQuery        = '',
    this.selectedBranchId   = 'branch_a',
  });

  final ProductCategory selectedCategory;
  final String selectedCategoryId;
  final String selectedSubFilter;
  final String searchQuery;
  final String selectedBranchId;

  PosFilterState copyWith({
    ProductCategory? selectedCategory,
    String?          selectedCategoryId,
    String?          selectedSubFilter,
    String?          searchQuery,
    String?          selectedBranchId,
  }) =>
      PosFilterState(
        selectedCategory:   selectedCategory   ?? this.selectedCategory,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        selectedSubFilter:  selectedSubFilter  ?? this.selectedSubFilter,
        searchQuery:        searchQuery        ?? this.searchQuery,
        selectedBranchId:   selectedBranchId   ?? this.selectedBranchId,
      );
}

// ============================================================
// Filter Notifier
// ============================================================

class PosFilterNotifier extends Notifier<PosFilterState> {
  @override
  PosFilterState build() {
    final defaultBranch = ref.watch(defaultBranchProvider);
    return PosFilterState(selectedBranchId: defaultBranch);
  }

  void selectCategory(ProductCategory cat) =>
      state = state.copyWith(
        selectedCategory: cat,
        selectedCategoryId: cat == ProductCategory.all ? 'all' : cat.name,
        selectedSubFilter: 'All',
      );

  void selectCategoryItem(CategoryItem? item) {
    if (item == null) {
      state = state.copyWith(
        selectedCategory: ProductCategory.all,
        selectedCategoryId: 'all',
        selectedSubFilter: 'All',
      );
    } else {
      state = state.copyWith(
        selectedCategory: item.standardCategory ?? ProductCategory.others,
        selectedCategoryId: item.id,
        selectedSubFilter: 'All',
      );
    }
  }

  void selectSubFilter(String sub) =>
      state = state.copyWith(selectedSubFilter: sub);

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void selectBranch(String branchId) {
    state = state.copyWith(selectedBranchId: branchId);
    ref.read(inventoryProvider.notifier).loadBranchStock(branchId);
  }
}

final posFilterProvider =
    NotifierProvider<PosFilterNotifier, PosFilterState>(PosFilterNotifier.new);

// ============================================================
// Derived: Filtered Products Provider
// ============================================================

final filteredProductsProvider = Provider<List<MockProduct>>((ref) {
  final productsList = ref.watch(catalogProvider);
  final filter = ref.watch(posFilterProvider);
  final inv = ref.watch(inventoryProvider);
  final categories = ref.watch(categoryNotifierProvider);
  var products = productsList.map((p) {
    return p.copyWith(stock: inv.getStock(filter.selectedBranchId, p.id));
  }).toList();

  final origins = ref.watch(activePlantOriginsProvider);
  final originNamesList = origins.map((o) => o.name).toList();

  CategoryItem? matchedCatItem;

  // ── Category filter ───────────────────────────────────────
  if (filter.selectedCategoryId != 'all') {
    matchedCatItem = categories
            .where((c) => c.id == filter.selectedCategoryId)
            .firstOrNull ??
        categories
            .where((c) =>
                c.standardCategory != null &&
                c.standardCategory!.name == filter.selectedCategoryId)
            .firstOrNull;
    products = products
        .where((p) => p.matchesCategory(
              selectedCategoryId: filter.selectedCategoryId,
              standardCategory: matchedCatItem != null
                  ? matchedCatItem.standardCategory
                  : (filter.selectedCategory != ProductCategory.all
                      ? filter.selectedCategory
                      : null),
              catName: matchedCatItem?.name,
              catEnglishName: matchedCatItem?.englishName,
            ))
        .toList();
  } else if (filter.selectedCategory != ProductCategory.all) {
    products = products
        .where((p) => p.category == filter.selectedCategory)
        .toList();
  }

  // ── Sub-filter (Subcategory & Plant Origin) ───────────────
  if (filter.selectedSubFilter != 'All' && filter.selectedSubFilter != 'အားလုံး') {
    final isPlantsCategory =
        matchedCatItem?.standardCategory == ProductCategory.plants ||
            (matchedCatItem == null &&
                filter.selectedCategory == ProductCategory.plants);
    products = products
        .where((p) => p.matchesSubFilter(
              filter.selectedSubFilter,
              isPlantsCategory: isPlantsCategory,
              originNames: originNamesList,
            ))
        .toList();
  }

  // ── Search query (Item name, Category, Vendor, Plant Origin, Barcode) ──
  if (filter.searchQuery.isNotEmpty) {
    final catNames = {for (final c in categories) c.id: '${c.name} ${c.englishName}'};
    final vendors = ref.watch(vendorProvider);
    final vendorNames = {for (final v in vendors) v.id: v.name};
    final originNames = {for (final o in origins) o.id: o.name};

    products = products
        .where((p) => p.matchesSearch(
              filter.searchQuery,
              categoryNames: catNames,
              vendorNames: vendorNames,
              originNames: originNames,
            ))
        .toList();
  }

  return products;
});
