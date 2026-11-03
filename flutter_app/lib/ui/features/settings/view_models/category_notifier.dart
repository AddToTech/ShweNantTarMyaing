import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/mock/mock_products.dart';

// ============================================================
// Domain / UI Model for Category and Subcategories
// ============================================================

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    this.englishName = '',
    required this.emoji,
    this.standardCategory,
    required this.subcategories,
    this.subcategoryIds = const {},
    this.isBuiltIn = false,
  });

  final String id;
  final String name; // Burmese name
  final String englishName;
  final String emoji;
  final ProductCategory? standardCategory; // Built-in enum link
  final List<String> subcategories;
  final Map<String, String> subcategoryIds;
  final bool isBuiltIn;

  CategoryItem copyWith({
    String? id,
    String? name,
    String? englishName,
    String? emoji,
    ProductCategory? standardCategory,
    List<String>? subcategories,
    Map<String, String>? subcategoryIds,
    bool? isBuiltIn,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      emoji: emoji ?? this.emoji,
      standardCategory: standardCategory ?? this.standardCategory,
      subcategories: subcategories ?? this.subcategories,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }
}

// ============================================================
// Initial Default Categories & Subcategories State (Dynamic Only)
// ============================================================

const List<CategoryItem> kDefaultCategories = [];

// ============================================================
// Category State Notifier
// ============================================================

final categoryLoadingProvider = StateProvider<bool>((ref) => true);

class CategoryNotifier extends Notifier<List<CategoryItem>> {
  @override
  List<CategoryItem> build() {
    loadCategories();
    return const [];
  }

  /// Load categories and subcategories from remote PostgreSQL backend
  Future<void> loadCategories() async {
    ref.read(categoryLoadingProvider.notifier).state = true;
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/categories');
      if (data is List) {
        final List<CategoryItem> loaded = [];
        for (final cat in data) {
          final catMap = cat as Map<String, dynamic>;
          final catName = catMap['name']?.toString() ?? '';
          final catId = catMap['id']?.toString() ?? '';
          final dbBurmeseName = catMap['burmese_name']?.toString() ?? '';
          final dbEmoji = catMap['emoji']?.toString() ?? '';

          ProductCategory? std;
          String defaultEmoji = '🏷️';
          String defaultBurmese = catName;
          final lower = catName.toLowerCase();

          if (lower == 'plant chemicals' ||
              lower == 'chemicals & fertilizers' ||
              lower == 'chemicals' ||
              dbBurmeseName == 'ဆေး/မြေသြဇာ') {
            std = ProductCategory.chemicals;
            defaultEmoji = '🧪';
            defaultBurmese = 'ဆေး/မြေသြဇာ';
          } else if (lower == 'plants' || dbBurmeseName == 'အပင်များ') {
            std = ProductCategory.plants;
            defaultEmoji = '🌱';
            defaultBurmese = 'အပင်များ';
          } else if (lower == 'pots' || dbBurmeseName == 'ပန်းအိုးများ') {
            std = ProductCategory.pots;
            defaultEmoji = '🪴';
            defaultBurmese = 'ပန်းအိုးများ';
          } else if (lower == 'gardening tools' ||
              lower == 'tools' ||
              dbBurmeseName == 'ကိရိယာများ') {
            std = ProductCategory.tools;
            defaultEmoji = '✂️';
            defaultBurmese = 'ကိရိယာများ';
          } else if (lower == 'others' || dbBurmeseName == 'အခြား') {
            std = ProductCategory.others;
            defaultEmoji = '📦';
            defaultBurmese = 'အခြား';
          }

          final burmeseName =
              dbBurmeseName.isNotEmpty ? dbBurmeseName : defaultBurmese;
          final emoji = (dbEmoji.isNotEmpty && dbEmoji != '🏷️')
              ? dbEmoji
              : (std != null ? defaultEmoji : (dbEmoji.isNotEmpty ? dbEmoji : '🏷️'));

          final List<String> subs = [];
          final Map<String, String> subIds = {};
          for (final rawSub in (catMap['subcategories'] as List? ?? [])) {
            final subMap = rawSub as Map<String, dynamic>;
            final sName = subMap['name']?.toString() ?? '';
            final sId = subMap['id']?.toString() ?? '';
            if (sName.isNotEmpty) {
              subs.add(sName);
              if (sId.isNotEmpty) {
                subIds[sName] = sId;
              }
            }
          }

          loaded.add(CategoryItem(
            id: catId,
            name: burmeseName,
            englishName: catName,
            emoji: emoji,
            standardCategory: std,
            subcategories: subs,
            subcategoryIds: subIds,
            isBuiltIn: std != null,
          ));
        }

        state = loaded;
      }
    } catch (_) {
    } finally {
      ref.read(categoryLoadingProvider.notifier).state = false;
    }
  }

  /// Create a new category
  Future<bool> addCategory({
    required String name,
    String englishName = '',
    required String emoji,
    List<String> subcategories = const [],
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final created = await client.post('/categories', body: {
        'name': englishName.trim().isNotEmpty ? englishName.trim() : name.trim(),
        'burmeseName': name.trim(),
        'emoji': emoji.trim().isNotEmpty ? emoji.trim() : '🏷️',
      });
      final createdId = (created is Map && created['id'] != null)
          ? created['id'].toString()
          : null;
      if (createdId != null && subcategories.isNotEmpty) {
        for (final sub in subcategories) {
          final clean = sub.trim();
          if (clean.isNotEmpty) {
            await client.post('/categories/$createdId/subcategories', body: {
              'name': clean,
            });
          }
        }
      }
      await loadCategories();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String id,
    required String name,
    String englishName = '',
    required String emoji,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/categories/$id', body: {
        'name': englishName.trim().isNotEmpty ? englishName.trim() : name.trim(),
        'burmeseName': name.trim(),
        'emoji': emoji.trim().isNotEmpty ? emoji.trim() : '🏷️',
      });
      await loadCategories();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a category by ID
  Future<bool> deleteCategory(String id) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/categories/$id');
      state = state.where((c) => c.id != id).toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Add a subcategory to a specific category
  Future<bool> addSubcategory(String categoryId, String subcategoryName) async {
    final cleanName = subcategoryName.trim();
    if (cleanName.isEmpty) return false;

    try {
      final client = ref.read(apiClientProvider);
      await client.post('/categories/$categoryId/subcategories', body: {
        'name': cleanName,
      });
      await loadCategories();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Rename / update an existing subcategory in the backend database
  Future<bool> updateSubcategory(
    String categoryId,
    String oldName,
    String newName,
  ) async {
    final cleanNewName = newName.trim();
    if (cleanNewName.isEmpty) return false;

    final cat = state.where((c) => c.id == categoryId).firstOrNull;
    final subId = cat?.subcategoryIds[oldName];
    if (subId == null || subId.isEmpty) return false;

    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/subcategories/$subId', body: {
        'name': cleanNewName,
      });
      await loadCategories();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a subcategory from the backend database
  Future<bool> deleteSubcategory(
    String categoryId,
    String subcategoryName,
  ) async {
    final cat = state.where((c) => c.id == categoryId).firstOrNull;
    final subId = cat?.subcategoryIds[subcategoryName];
    if (subId == null || subId.isEmpty) return false;

    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/subcategories/$subId');
      await loadCategories();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reload categories from the backend database
  Future<void> resetToDefaults() async {
    await loadCategories();
  }

  /// Get subcategories for a ProductCategory enum or custom CategoryItem ID
  List<String> getSubcategoriesForCategory(
    ProductCategory category, {
    String? categoryId,
  }) {
    if (categoryId != null && categoryId.isNotEmpty) {
      final byId = state.where((c) => c.id == categoryId).firstOrNull;
      if (byId != null) return byId.subcategories;
    }
    final item = state.firstWhere(
      (c) => c.standardCategory == category,
      orElse: () => const CategoryItem(id: '', name: '', emoji: '', subcategories: []),
    );
    return item.subcategories;
  }
}

final categoryNotifierProvider =
    NotifierProvider<CategoryNotifier, List<CategoryItem>>(CategoryNotifier.new);
