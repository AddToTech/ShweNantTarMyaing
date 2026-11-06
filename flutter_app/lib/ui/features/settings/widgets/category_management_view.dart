import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../view_models/category_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

// ============================================================
// Category & Subcategory Management View (CRUD)
// ============================================================

class CategoryManagementView extends ConsumerStatefulWidget {
  const CategoryManagementView({super.key});

  @override
  ConsumerState<CategoryManagementView> createState() =>
      _CategoryManagementViewState();
}

class _CategoryManagementViewState
    extends ConsumerState<CategoryManagementView> {
  String? _selectedCategoryId;
  final _searchCategoryCtrl = TextEditingController();
  final _searchSubcategoryCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCategoryCtrl.dispose();
    _searchSubcategoryCtrl.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog({CategoryItem? category}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditCategoryDialog(categoryToEdit: category),
    );
  }

  void _confirmDeleteCategory(CategoryItem category) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'အမျိုးအစား ဖျက်ရန် သေချာပါသလား?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'အမျိုးအစား "${category.name}" (${category.englishName}) နှင့် ၎င်းတွင်ပါဝင်သော အုပ်စုခွဲ (${category.subcategories.length}) ခုစလုံးကို စာရင်းမှ ဖယ်ရှားပါမည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ (Cancel)',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(categoryNotifierProvider.notifier)
                  .deleteCategory(category.id);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('အမျိုးအစား "${category.name}" ကို ဖျက်ပြီးပါပြီ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('အမျိုးအစား "${category.name}" ကို ဖျက်၍ မအောင်မြင်ပါ'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ဖျက်မည် (Delete)'),
          ),
        ],
      ),
    );
  }

  void _showAddEditSubcategoryDialog(
      {required String categoryId,
      required String categoryName,
      String? oldSubName}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditSubcategoryDialog(
        categoryId: categoryId,
        categoryName: categoryName,
        oldSubName: oldSubName,
      ),
    );
  }

  void _confirmDeleteSubcategory(
      {required String categoryId, required String subName}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'အုပ်စုခွဲ ဖျက်မလား?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'အုပ်စုခွဲ "$subName" ကို စာရင်းမှ ဖယ်ရှားပါမည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(categoryNotifierProvider.notifier)
                  .deleteSubcategory(categoryId, subName);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('အုပ်စုခွဲ "$subName" ကို ဖယ်ရှားပြီးပါပြီ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('အုပ်စုခွဲ "$subName" ကို ဖယ်ရှား၍ မအောင်မြင်ပါ'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restore_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Text(
              'မူလသတ်မှတ်ချက်အတိုင်း ပြန်ထားမလား?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Category နှင့် Subcategory စာရင်းများကို မူလစနစ်သတ်မှတ်ချက် (အပင် ၆ မျိုး၊ ပန်းအိုး ၆ မျိုး၊ ဆေး ၃ မျိုး စသည်) အတိုင်း ပြန်လည်သတ်မှတ်ပါမည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(categoryNotifierProvider.notifier).resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('မူလသတ်မှတ်ချက်အတိုင်း ပြန်လည်ထားရှိပြီးပါပြီ'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            child: const Text('မူလအတိုင်း ပြန်ထားမည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final isCategoryLoading = ref.watch(categoryLoadingProvider);

    // Auto-select first category if none or selected was deleted
    if (categories.isNotEmpty) {
      if (_selectedCategoryId == null ||
          !categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = categories.first.id;
      }
    } else {
      _selectedCategoryId = null;
    }

    final catQuery = _searchCategoryCtrl.text.trim().toLowerCase();
    final filteredCategories = categories.where((c) {
      if (catQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(catQuery) ||
          c.englishName.toLowerCase().contains(catQuery) ||
          c.subcategories.any((s) => s.toLowerCase().contains(catQuery));
    }).toList();

    final selectedCategory = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : const CategoryItem(
              id: '',
              name: 'မရှိပါ',
              emoji: '🏷️',
              subcategories: [],
            ),
    );

    final totalSubcategories =
        categories.fold(0, (sum, c) => sum + c.subcategories.length);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── KPI Summary Cards ─────────────────────────────────────
          Row(
            children: [
              _buildMetricCard(
                icon: '🏷️',
                title: 'Total Categories',
                burmese: 'အမျိုးအစား စုစုပေါင်း',
                count: '${categories.length} ခု',
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),
              _buildMetricCard(
                icon: '📂',
                title: 'Total Subcategories',
                burmese: 'အုပ်စုခွဲ စုစုပေါင်း',
                count: '$totalSubcategories မျိုး',
                color: Colors.amber,
              ),
              const SizedBox(width: 14),
              _buildMetricCard(
                icon: '🌱',
                title: 'Plants Types',
                burmese: 'အပင်အမျိုးအစားများ',
                count:
                    '${categories.where((c) => c.standardCategory == ProductCategory.plants).firstOrNull?.subcategories.length ?? 0} မျိုး',
                color: AppColors.success,
              ),
              const SizedBox(width: 14),
              _buildMetricCard(
                icon: '🪴',
                title: 'Pots & Chemicals',
                burmese: 'ပန်းအိုးနှင့် ဆေးဝါးများ',
                count:
                    '${(categories.where((c) => c.standardCategory == ProductCategory.pots).firstOrNull?.subcategories.length ?? 0) + (categories.where((c) => c.standardCategory == ProductCategory.chemicals).firstOrNull?.subcategories.length ?? 0)} မျိုး',
                color: Colors.lightBlueAccent,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Two-Column CRUD Work Area ─────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left Column: Category List (380px) ──────────────
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Header & Add Category Button
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: BoxDecoration(
                          color: AppColors.navRailBg,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(16)),
                          border: Border(
                              bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Categories',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${categories.length}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.restore_rounded,
                                          size: 18, color: AppColors.textMuted),
                                      tooltip: 'မူလသတ်မှတ်ချက်အတိုင်း ပြန်ထားမည်',
                                      onPressed: _confirmResetDefaults,
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddEditCategoryDialog(),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16),
                                      label: const Text('အသစ်ထည့်',
                                          style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor:
                                            AppColors.textOnPrimary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Search Box
                            SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _searchCategoryCtrl,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'အမျိုးအစား ရှာဖွေပါ...',
                                  hintStyle: TextStyle(
                                      color: AppColors.textMuted, fontSize: 11.5),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      size: 16, color: AppColors.textMuted),
                                  suffixIcon:
                                      _searchCategoryCtrl.text.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () => setState(() =>
                                                  _searchCategoryCtrl.clear()),
                                              child: Icon(
                                                  Icons.close_rounded,
                                                  size: 14,
                                                  color: AppColors.textMuted),
                                            )
                                          : null,
                                  filled: true,
                                  fillColor: AppColors.surfaceVariant,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category List
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onRefresh: () async {
                            await ref.read(categoryNotifierProvider.notifier).loadCategories();
                          },
                          child: isCategoryLoading && filteredCategories.isEmpty
                              ? const Center(
                                  child: AppLoadingView(
                                    compact: true,
                                    message: 'အမျိုးအစားများ ရယူနေပါသည်...',
                                  ),
                                )
                              : filteredCategories.isEmpty
                                  ? CustomScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Text(
                                          'ရှာဖွေမှုနှင့် ကိုက်ညီသော အမျိုးအစား မရှိပါ',
                                          style: TextStyle(
                                              color: AppColors.textMuted, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredCategories.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  final isSelected =
                                      cat.id == _selectedCategoryId;

                                  return InkWell(
                                    onTap: () {
                                      setState(() =>
                                          _selectedCategoryId = cat.id);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                                .withValues(alpha: 0.14)
                                            : AppColors.surfaceVariant,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(cat.emoji,
                                                style: const TextStyle(
                                                    fontSize: 20)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cat.name,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (cat
                                                    .englishName.isNotEmpty) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    cat.englishName,
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    '${cat.subcategories.length} အုပ်စုခွဲ',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color:
                                                    AppColors.textSecondary),
                                            tooltip: 'ပြင်ဆင်မည်',
                                            onPressed: () =>
                                                _showAddEditCategoryDialog(
                                                    category: cat),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 16,
                                                color: AppColors.error),
                                            tooltip: 'ဖျက်မည်',
                                            onPressed: () =>
                                                _confirmDeleteCategory(cat),
                                          ),
                                        ],
                                      ),
                                    ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                // ── Right Column: Subcategories Management (Expanded) ──
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: selectedCategory.id.isEmpty
                        ? Center(
                            child: Text(
                              'ဘယ်ဘက်မှ အမျိုးအစားတစ်ခု ရွေးချယ်ပါ',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 14),
                            ),
                          )
                        : _buildSubcategoriesPane(selectedCategory),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesPane(CategoryItem cat) {
    final subQuery = _searchSubcategoryCtrl.text.trim().toLowerCase();
    final filteredSubs = cat.subcategories.where((s) {
      if (subQuery.isEmpty) return true;
      return s.toLowerCase().contains(subQuery);
    }).toList();

    return Column(
      children: [
        // Category Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.navRailBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${cat.name} — အုပ်စုခွဲများ (Subcategories)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (cat.englishName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '(${cat.englishName})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'စုစုပေါင်း အုပ်စုခွဲ ${cat.subcategories.length} ခု စာရင်းသွင်းထားပါသည်',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditSubcategoryDialog(
                  categoryId: cat.id,
                  categoryName: cat.name,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ အုပ်စုခွဲအသစ် ထည့်မည်',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
              ),
            ],
          ),
        ),

        // Subcategory Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchSubcategoryCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          '${cat.name} အတွင်း အုပ်စုခွဲ အမည်ဖြင့် ရှာဖွေပါ...',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchSubcategoryCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => setState(
                                  () => _searchSubcategoryCtrl.clear()),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textMuted),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ပြသထားသော အုပ်စုခွဲ: ${filteredSubs.length} ခု',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),

        // Subcategory Cards Grid
        Expanded(
          child: filteredSubs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(Icons.category_outlined,
                            size: 40, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat.subcategories.isEmpty
                            ? 'ဤ အမျိုးအစားတွင် အုပ်စုခွဲ မရှိသေးပါ'
                            : 'ရှာဖွေမှုနှင့် ကိုက်ညီသော အုပ်စုခွဲ မရှိပါ',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.subcategories.isEmpty
                            ? 'အထက်ပါ "+ အုပ်စုခွဲအသစ် ထည့်မည်" ခလုတ်ကို နှိပ်၍ စတင်ထည့်သွင်းပါ'
                            : 'အခြား အမည်ဖြင့် ပြန်လည်ရှာဖွေပါ',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // 2 columns gives ample width (~300px+) so Burmese titles show fully without being truncated.
                    final crossAxisCount = constraints.maxWidth > 920 ? 3 : 2;
                    final childAspectRatio = crossAxisCount == 3 ? 2.8 : 3.4;

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: filteredSubs.length,
                      itemBuilder: (context, idx) {
                        final sub = filteredSubs[idx];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.tag_rounded,
                                    size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Tooltip(
                                  message: sub,
                                  child: Text(
                                    sub,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'အမည်ပြင်ဆင်မည် (Rename)',
                                child: InkWell(
                                  onTap: () => _showAddEditSubcategoryDialog(
                                    categoryId: cat.id,
                                    categoryName: cat.name,
                                    oldSubName: sub,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.border
                                              .withValues(alpha: 0.6)),
                                    ),
                                    child: Icon(Icons.edit_outlined,
                                        size: 15,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'ဖျက်မည် (Delete)',
                                child: InkWell(
                                  onTap: () => _confirmDeleteSubcategory(
                                    categoryId: cat.id,
                                    subName: sub,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 15,
                                        color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String title,
    required String burmese,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(burmese,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 9.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Add / Edit Category Dialog
// ============================================================

class _AddEditCategoryDialog extends ConsumerStatefulWidget {
  const _AddEditCategoryDialog({this.categoryToEdit});
  final CategoryItem? categoryToEdit;

  @override
  ConsumerState<_AddEditCategoryDialog> createState() =>
      _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState
    extends ConsumerState<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _englishNameCtrl;
  late TextEditingController _initialSubsCtrl;
  String _selectedEmoji = '🌱';

  static const _emojiPresets = [
    '🌱', '🪴', '🧪', '✂️', '📦', '🌸', '🌳', '🌾', '🍄', '🪨', '🏺', '🏷️'
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _englishNameCtrl = TextEditingController(text: c?.englishName ?? '');
    _initialSubsCtrl = TextEditingController(
        text: c != null ? c.subcategories.join(', ') : '');
    _selectedEmoji = c?.emoji ?? '🌱';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _englishNameCtrl.dispose();
    _initialSubsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.categoryToEdit != null;
    final notifier = ref.read(categoryNotifierProvider.notifier);

    bool ok;
    if (isEdit) {
      ok = await notifier.updateCategory(
        id: widget.categoryToEdit!.id,
        name: _nameCtrl.text.trim(),
        englishName: _englishNameCtrl.text.trim(),
        emoji: _selectedEmoji,
      );
    } else {
      final subList = _initialSubsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      ok = await notifier.addCategory(
        name: _nameCtrl.text.trim(),
        englishName: _englishNameCtrl.text.trim(),
        emoji: _selectedEmoji,
        subcategories: subList,
      );
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.categoryToEdit != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_selectedEmoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit
                        ? 'အမျိုးအစား ပြင်ဆင်ရန် (Edit Category)'
                        : 'အမျိုးအစား အသစ်ထည့်ရန် (Add Category)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Emoji Selector Chips
              Text(
                'အိုင်ကွန် / အီမိုဂျီ ရွေးချယ်ပါ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emojiPresets.map((e) {
                  final isSel = _selectedEmoji == e;
                  return InkWell(
                    onTap: () => setState(() => _selectedEmoji = e),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Burmese Name Field
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'အမျိုးအစား အမည် (မြန်မာ)*',
                  labelStyle:
                      TextStyle(color: AppColors.textSecondary),
                  hintText: 'ဥပမာ - အပင်များ၊ ပန်းအိုးများ',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'အမျိုးအစား အမည် ထည့်သွင်းပေးပါ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // English Name Field
              TextFormField(
                controller: _englishNameCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Category Name (English)',
                  labelStyle:
                      TextStyle(color: AppColors.textSecondary),
                  hintText: 'e.g. Plants, Pots, Fertilizers',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _initialSubsCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'ကနဦး အုပ်စုခွဲများ (ကော်မာဖြင့် ခြားနိုင်သည်)',
                    labelStyle:
                        TextStyle(color: AppColors.textSecondary),
                    hintText: 'ဥပမာ - အလှပင်, အသီးပင်, သစ်ခွ',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('မလုပ်တော့ပါ',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: Text(isEdit ? 'သိမ်းဆည်းမည်' : 'ထည့်သွင်းမည်'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Add / Edit Subcategory Dialog
// ============================================================

class _AddEditSubcategoryDialog extends ConsumerStatefulWidget {
  const _AddEditSubcategoryDialog({
    required this.categoryId,
    required this.categoryName,
    this.oldSubName,
  });

  final String categoryId;
  final String categoryName;
  final String? oldSubName;

  @override
  ConsumerState<_AddEditSubcategoryDialog> createState() =>
      _AddEditSubcategoryDialogState();
}

class _AddEditSubcategoryDialogState
    extends ConsumerState<_AddEditSubcategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subNameCtrl;

  @override
  void initState() {
    super.initState();
    _subNameCtrl =
        TextEditingController(text: widget.oldSubName ?? '');
  }

  @override
  void dispose() {
    _subNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.oldSubName != null;
    final notifier = ref.read(categoryNotifierProvider.notifier);

    bool ok;
    if (isEdit) {
      ok = await notifier.updateSubcategory(
        widget.categoryId,
        widget.oldSubName!,
        _subNameCtrl.text.trim(),
      );
    } else {
      ok = await notifier.addSubcategory(
        widget.categoryId,
        _subNameCtrl.text.trim(),
      );
    }
    if (!ok || !mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.oldSubName != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tag_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'အုပ်စုခွဲ အမည်ပြင်ဆင်ရန်'
                              : 'အုပ်စုခွဲ အသစ်ထည့်သွင်းရန်',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Category: ${widget.categoryName}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _subNameCtrl,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'အုပ်စုခွဲ အမည် (Subcategory Name)*',
                  labelStyle:
                      TextStyle(color: AppColors.textSecondary),
                  hintText: 'ဥပမာ - နှစ်ရှည်အလှပင်၊ ကြွေအိုး၊ အမြစ်ဆေး',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'အုပ်စုခွဲ အမည် ထည့်သွင်းပေးပါ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('မလုပ်တော့ပါ',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: Text(isEdit ? 'သိမ်းဆည်းမည်' : 'ထည့်မည်'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
