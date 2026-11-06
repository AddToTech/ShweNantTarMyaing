import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../view_models/pos_filter_notifier.dart';

import '../../settings/view_models/category_notifier.dart';
import '../../settings/view_models/plant_origin_notifier.dart';

// ============================================================
// CategoryFilterBar
// Renders the horizontal category tabs + conditional sub-chips
// ============================================================

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  static String _getSubFilterLabel(String sub) => switch (sub) {
    'All' || 'အားလုံး' => 'အားလုံး (All)',
    'ယိုးဒယား Import' || 'Thai Import' => '🇹🇭 ယိုးဒယား Import',
    'တရုတ် Import' || 'China Import' => '🇨🇳 တရုတ် Import',
    'ပြည်တွင်း' || 'Local' => '🇲🇲 ပြည်တွင်း',
    'နှစ်ရှည်အလှပင်' => '🌸 နှစ်ရှည်အလှပင်',
    'နှစ်ရှည်အသီးပင်' => '🥭 နှစ်ရှည်အသီးပင်',
    'Indoor ပင်' => '🪴 Indoor ပင်',
    'သစ်ခွ' => '🌺 သစ်ခွ',
    'မျိုးစေ့' => '🌱 မျိုးစေ့',
    'အထွေထွေ' => '🌿 အထွေထွေ',
    'ကြွေအိုး' => '🏺 ကြွေအိုး',
    'ကော်အိုး' => '🪣 ကော်အိုး',
    'ဘွန်စိုင်း' => '🎍 ဘွန်စိုင်း',
    'ကွန်ကရစ်' => '🧱 ကွန်ကရစ်',
    'စဥ့်အိုး' => '🏺 စဥ့်အိုး',
    'မြေအိုး' => '🪴 မြေအိုး',
    'အမြစ်ဆေး' => '💧 အမြစ်ဆေး',
    'အပွင့်ဆေး' => '🌸 အပွင့်ဆေး',
    '၁၅-၁၆ ပတ်လည်' => '🧪 ၁၅-၁၆ ပတ်လည်',
    'ကိုင်းညှပ်' => '✂️ ကိုင်းညှပ်',
    'ဓား' => '🔪 ဓား',
    'ရေလောင်း' => '🚿 ရေလောင်း',
    'မြေတူး' => '⛏️ မြေတူး',
    'မြေဆွေး' => '🌍 မြေဆွေး',
    'ကျောက်စရစ်' => '🪨 ကျောက်စရစ်',
    _ => sub,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter   = ref.watch(posFilterProvider);
    final notifier = ref.read(posFilterProvider.notifier);
    final activeCategories = ref.watch(categoryNotifierProvider);

    final catItem = activeCategories
        .where((c) =>
            c.id == filter.selectedCategoryId ||
            (filter.selectedCategoryId != 'all' &&
                c.standardCategory != null &&
                c.standardCategory == filter.selectedCategory))
        .firstOrNull;
    final dynamicSubList = catItem != null
        ? ['All', ...catItem.subcategories]
        : const <String>[];

    final isPlantsCategory =
        catItem?.standardCategory == ProductCategory.plants ||
            (catItem == null &&
                filter.selectedCategory == ProductCategory.plants);

    final origins = ref.watch(activePlantOriginsProvider);
    final originNames = origins.map((o) => o.name).toList();

    final subFilters = isPlantsCategory
        ? [
            ...dynamicSubList,
            for (final oName in originNames)
              if (!dynamicSubList.contains(oName)) oName,
          ]
        : dynamicSubList;

    final hasSubFilters =
        filter.selectedCategoryId != 'all' && subFilters.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Category tabs ─────────────────────────────────
        Container(
          height: 46,
          color: AppColors.navRailBg,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: activeCategories.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return _CategoryTab(
                  label: 'အားလုံး (All)',
                  emoji: '🌿',
                  isSelected: filter.selectedCategoryId == 'all',
                  onTap: () => notifier.selectCategoryItem(null),
                );
              }
              final c = activeCategories[i - 1];
              final label = c.englishName.isNotEmpty &&
                      c.englishName.toLowerCase() != c.name.toLowerCase()
                  ? '${c.name} (${c.englishName})'
                  : c.name;
              final isSelected = filter.selectedCategoryId == c.id ||
                  (c.standardCategory != null &&
                      filter.selectedCategoryId == c.standardCategory!.name);
              return _CategoryTab(
                label: label,
                emoji: c.emoji,
                isSelected: isSelected,
                onTap: () => notifier.selectCategoryItem(c),
              );
            },
          ),
        ),

        // Thin rule below tabs
        Container(height: 1, color: AppColors.border),

        // ── Sub-filter chips (animated in/out) ────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: hasSubFilters
              ? Container(
                  height: 42,
                  color: AppColors.surface.withValues(alpha: 0.8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: subFilters.length,
                    itemBuilder: (_, i) {
                      final sub = subFilters[i];
                      return _SubFilterChip(
                        label: _getSubFilterLabel(sub),
                        isSelected: filter.selectedSubFilter == sub,
                        onTap: () => notifier.selectSubFilter(sub),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (hasSubFilters)
          Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ── Category tab ──────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-filter chip ───────────────────────────────────────

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
