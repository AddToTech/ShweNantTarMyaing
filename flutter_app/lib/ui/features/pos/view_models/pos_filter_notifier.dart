import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../settings/view_models/category_notifier.dart';

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
  PosFilterState build() => const PosFilterState();

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

  // ── Category filter ───────────────────────────────────────
  if (filter.selectedCategoryId != 'all') {
    final catItem = categories
        .where((c) =>
            c.id == filter.selectedCategoryId ||
            (c.standardCategory != null &&
                c.standardCategory!.name == filter.selectedCategoryId))
        .firstOrNull;
    products = products
        .where((p) => p.matchesCategory(
              selectedCategoryId: filter.selectedCategoryId,
              standardCategory: catItem?.standardCategory ??
                  (filter.selectedCategory != ProductCategory.all
                      ? filter.selectedCategory
                      : null),
              catName: catItem?.name,
              catEnglishName: catItem?.englishName,
            ))
        .toList();
  } else if (filter.selectedCategory != ProductCategory.all) {
    products = products
        .where((p) => p.category == filter.selectedCategory)
        .toList();
  }

  // ── Sub-filter ────────────────────────────────────────────
  if (filter.selectedSubFilter != 'All' && filter.selectedSubFilter != 'အားလုံး') {
    if (filter.selectedCategory == ProductCategory.plants) {
      if (filter.selectedSubFilter == 'Thai Import' ||
          filter.selectedSubFilter == 'ယိုးဒယား Import') {
        products = products
            .where((p) => p.originType == OriginType.thaiImport)
            .toList();
      } else if (filter.selectedSubFilter == 'China Import' ||
          filter.selectedSubFilter == 'တရုတ် Import') {
        products = products
            .where((p) => p.originType == OriginType.chinaImport)
            .toList();
      } else if (filter.selectedSubFilter == 'Local' ||
          filter.selectedSubFilter == 'ပြည်တွင်း') {
        products = products
            .where((p) => p.originType == OriginType.local)
            .toList();
      } else {
        // Filter by plant subcategory: နှစ်ရှည်အလှပင်, နှစ်ရှည်အသီးပင်, Indoor ပင်, သစ်ခွ, မျိုးစေ့, အထွေထွေ
        products = products
            .where((p) => p.subcategory == filter.selectedSubFilter)
            .toList();
      }
    } else {
      // Other categories: filter by subcategory name
      products = products
          .where((p) => p.subcategory == filter.selectedSubFilter)
          .toList();
    }
  }

  // ── Search query ──────────────────────────────────────────
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    products = products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode?.contains(q) ?? false))
        .toList();
  }

  return products;
});
