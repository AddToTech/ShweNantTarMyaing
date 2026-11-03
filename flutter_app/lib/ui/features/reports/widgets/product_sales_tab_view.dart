import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../view_models/product_sales_report_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

class ProductSalesTabView extends ConsumerWidget {
  const ProductSalesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat('#,###');
    final filter = ref.watch(productSalesReportFilterProvider);
    final items = ref.watch(productWiseSalesDataProvider);

    // Compute top KPIs
    final totalUnitsSold = items.fold(0, (acc, item) => acc + item.soldQuantity);
    final totalRevenue = items.fold(0.0, (acc, item) => acc + item.revenueTotal);
    final totalCost = items.fold(0.0, (acc, item) => acc + item.costTotal);
    final totalProfit = totalRevenue - totalCost;
    final overallMargin =
        totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

    return Column(
      children: [
        // ── Filter & Sort Bar ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Category Filter Dropdown
              Builder(
                builder: (context) {
                  final activeCategories = ref.watch(categoryNotifierProvider);
                  final validIds = {'all', ...activeCategories.map((c) => c.id)};
                  final currentId = validIds.contains(filter.categoryId)
                      ? filter.categoryId
                      : 'all';
                  return Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentId,
                        dropdownColor: AppColors.surfaceVariant,
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.primary),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              'All Categories (ကဏ္ဍအားလုံး)',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 12),
                            ),
                          ),
                          ...activeCategories.map((cat) {
                            final label = cat.englishName.isNotEmpty &&
                                    cat.englishName.toLowerCase() !=
                                        cat.name.toLowerCase()
                                ? '${cat.emoji} ${cat.englishName} (${cat.name})'
                                : '${cat.emoji} ${cat.name}';
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(
                                label,
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 12),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final matched = activeCategories
                                .where((c) => c.id == val)
                                .firstOrNull;
                            ref
                                .read(productSalesReportFilterProvider.notifier)
                                .setCategoryId(
                                  val,
                                  stdCategory: matched?.standardCategory,
                                );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Origin Filter Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filter.originFilter,
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Origins (မူရင်းအားလုံး)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'thaiImport',
                        child: Text('🇹🇭 ယိုးဒယား Import',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'chinaImport',
                        child: Text('🇨🇳 တရုတ် Import',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'local',
                        child: Text('🇲🇲 ပြည်တွင်း',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(productSalesReportFilterProvider.notifier)
                            .setOrigin(val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Search Box
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => ref
                              .read(productSalesReportFilterProvider.notifier)
                              .setSearchQuery(val),
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'ကုန်ပစ္စည်းအမည် ရှာဖွေပါ...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted, fontSize: 11.5),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductSalesSortBy>(
                    value: filter.sortBy,
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.sort_rounded,
                        color: AppColors.primary, size: 16),
                    items: ProductSalesSortBy.values.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(sort.label,
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(productSalesReportFilterProvider.notifier)
                            .setSortBy(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Data Table Header ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.navRailBg,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('ကုန်ပစ္စည်းအမည် (PRODUCT)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('အမျိုးအစား (CATEGORY)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 100,
                child: Text('မူရင်းနိုင်ငံ (ORIGIN)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 90,
                child: Text('ရောင်းရဦးရေ (QTY)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('ဝယ်ရင်းစရိတ် (COST)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('ရောင်းရငွေ (REVENUE)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Text('အမြတ်ငွေ (PROFIT & %)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // ── Data Table Body ───────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await ref.read(catalogProvider.notifier).loadProducts();
              final _ = await ref.refresh(remoteSalesProvider.future);
            },
            child: ((ref.watch(remoteSalesProvider).isLoading || ref.watch(catalogLoadingProvider)) && items.isEmpty)
                ? const Center(
                    child: AppLoadingView(
                      message: 'ကုန်ပစ္စည်းအရောင်း အစီရင်ခံစာများ တွက်ချက်ရယူနေပါသည်...',
                      subMessage: 'Calculating product sales from records...',
                      icon: Icons.insights_rounded,
                    ),
                  )
                : items.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'စစ်ထုတ်ချက်နှင့် ကိုက်ညီသော ပစ္စည်းမရှိပါ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, thickness: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          // Product Name
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Category
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.categoryName?.isNotEmpty == true
                                  ? item.categoryName!
                                  : _categoryLabel(item.category),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Origin Badge
                          SizedBox(
                            width: 100,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _originBadge(item.originType),
                            ),
                          ),

                          // Sold Quantity
                          SizedBox(
                            width: 90,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.soldQuantity > 0
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.soldQuantity}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: item.soldQuantity > 0
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Cost Total
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.costTotal)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Revenue Total
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.revenueTotal)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Gross Margin (Ks & %)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+${currencyFmt.format(item.grossProfit)} Ks',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${item.grossMarginPercent.toStringAsFixed(1)}% အမြတ်',
                                  style: TextStyle(
                                    color: item.grossMarginPercent >= 30
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),

        // ── Summary Footer ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.navRailBg,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                'စစ်ဆေးထားသော ပစ္စည်း: ${items.length} မျိုး',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              _footerStat(
                label: 'ရောင်းရဦးရေစုစုပေါင်း',
                value: '$totalUnitsSold pcs',
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 28),

              _footerStat(
                label: 'ဝယ်ရင်းစရိတ်စုစုပေါင်း',
                value: '${currencyFmt.format(totalCost)} Ks',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 28),

              _footerStat(
                label: 'အရောင်းရငွေစုစုပေါင်း',
                value: '${currencyFmt.format(totalRevenue)} Ks',
                color: AppColors.primary,
              ),
              const SizedBox(width: 28),

              _footerStat(
                label: 'အသားတင်အမြတ်စုစုပေါင်း',
                value:
                    '+${currencyFmt.format(totalProfit)} Ks (${overallMargin.toStringAsFixed(1)}%)',
                color: AppColors.accent,
                isHighlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footerStat({
    required String label,
    required String value,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isHighlight ? 14.5 : 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _originBadge(OriginType? origin) {
    if (origin == null) {
      return Text('-', style: TextStyle(color: AppColors.textMuted));
    }

    final (label, color) = switch (origin) {
      OriginType.thaiImport => ('🇹🇭 ယိုးဒယား Import', const Color(0xFF2563EB)),
      OriginType.chinaImport => ('🇨🇳 တရုတ် Import', const Color(0xFFDC2626)),
      OriginType.local => ('🇲🇲 ပြည်တွင်း', const Color(0xFF059669)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _categoryLabel(ProductCategory cat) {
    return switch (cat) {
      ProductCategory.plants => 'အပင်များ',
      ProductCategory.pots => 'ပန်းအိုးများ',
      ProductCategory.chemicals => 'ဓာတ်မြေသြဇာ/ဆေး',
      ProductCategory.tools => 'ကိရိယာများ',
      ProductCategory.others => 'အခြား',
      ProductCategory.all => 'အားလုံး',
    };
  }
}
