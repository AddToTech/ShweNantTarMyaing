import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../view_models/stock_valuation_report_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

class StockValuationTabView extends ConsumerWidget {
  const StockValuationTabView({super.key});

  void _triggerExport(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ကုန်ပစ္စည်းတန်ဖိုးတွက်ချက်မှု အစီရင်ခံစာ ($count မျိုး) CSV သို့ ထုတ်ယူပြီးပါပြီ။',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat('#,###');
    final filter = ref.watch(stockValuationFilterProvider);
    final summary = ref.watch(stockValuationReportProvider);

    return Column(
      children: [
        // ── Top Summary Metric Cards ──────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Total SKUs
              _metricCard(
                icon: Icons.category_rounded,
                title: 'စုစုပေါင်း ပစ္စည်းအမျိုးအစား (SKUs)',
                value: '${summary.totalSkus}',
                subtitle: 'လက်ရှိရောင်းချနေသော ပစ္စည်းများ',
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),

              // Total Stock Units
              _metricCard(
                icon: Icons.inventory_2_rounded,
                title: 'လက်ကျန်ပစ္စည်းဦးရေ (STOCK)',
                value: '${currencyFmt.format(summary.totalUnits)} pcs',
                subtitle: 'ဆိုင်ခွဲအားလုံးရှိ ပစ္စည်းဦးရေ',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 14),

              // Total Inventory Cost Value (အရင်းတန်ဖိုး)
              _metricCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'ကုန်ပစ္စည်း အရင်းတန်ဖိုး (COST ASSET)',
                value: '${currencyFmt.format(summary.totalCostValue)} Ks',
                subtitle: 'ဝယ်ရင်းစရိတ်အရ ရင်းနှီးငွေပမာဏ',
                color: AppColors.accent,
              ),
              const SizedBox(width: 14),

              // Potential Retail Value (ရောင်းစျေးတန်ဖိုး)
              _metricCard(
                icon: Icons.trending_up_rounded,
                title: 'မှန်းခြေ ရောင်းစျေးတန်ဖိုး (RETAIL VALUE)',
                value: '${currencyFmt.format(summary.potentialRetailValue)} Ks',
                subtitle: 'ရောင်းချပြီးပါက ရရှိမည့်ငွေ',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),

        // ── Search & Filter Action Bar ────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.navRailBg,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                              .read(stockValuationFilterProvider.notifier)
                              .setSearchQuery(val),
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'SKU၊ ဘားကုဒ်၊ ပစ္စည်းအမည် ရှာဖွေပါ...',
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

              // Category Selector
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentId,
                        dropdownColor: AppColors.surface,
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
                                .read(stockValuationFilterProvider.notifier)
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

              // Export to CSV Button
              ElevatedButton.icon(
                onPressed: () => _triggerExport(context, summary.items.length),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text(
                  'Export CSV (ဒေါင်းလုဒ်)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // ── Data Table Header ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 120,
                  child: Text('SKU / ကုဒ်',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 3,
                  child: Text('ကုန်ပစ္စည်းအမည် (PRODUCT)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 110,
                  child: Text('အမျိုးအစား (CATEGORY)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 80,
                  child: Text(
                      kBranches['branch_a']?.split('(').first.trim() ??
                          'ဆိုင်ခွဲ (က)',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 80,
                  child: Text(
                      kBranches['branch_b']?.split('(').first.trim() ??
                          'ဆိုင်ခွဲ (ခ)',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 90,
                  child: Text('လက်ကျန် (TOTAL)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('ဝယ်ရင်းစျေး (COST)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('ရောင်းစျေး (PRICE)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 3,
                  child: Text('စုစုပေါင်းအရင်းတန်ဖိုး (VALUE)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        // ── Data Table Body ───────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(catalogProvider.notifier).loadProducts(),
              ]);
            },
            child: (ref.watch(catalogLoadingProvider) && summary.items.isEmpty)
                ? const Center(
                    child: AppLoadingView(
                      message: 'သိုလှောင်ရုံ စာရင်းအချက်အလက်များ တွက်ချက်ရယူနေပါသည်...',
                      subMessage: 'Loading stock valuation...',
                      icon: Icons.warehouse_rounded,
                    ),
                  )
                : summary.items.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'ရှာဖွေမှုနှင့် ကိုက်ညီသော ကုန်ပစ္စည်းမရှိပါ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: summary.items.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, thickness: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = summary.items[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          // SKU / Code
                          SizedBox(
                            width: 120,
                            child: Text(
                              item.product.sku.isNotEmpty
                                  ? item.product.sku
                                  : item.product.id.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          // Product Name
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.product.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Category
                          SizedBox(
                            width: 110,
                            child: Text(
                              item.product.categoryName?.isNotEmpty == true
                                  ? item.product.categoryName!
                                  : _categoryName(item.product.category),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Branch A Stock
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${item.branchAStock}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Branch B Stock
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${item.branchBStock}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Total Stock
                          SizedBox(
                            width: 90,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.totalStock > 0
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.totalStock} pcs',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: item.totalStock > 0
                                      ? AppColors.primary
                                      : AppColors.error,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Unit Cost
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.unitCost)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Retail Price
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.unitPrice)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Total Inventory Asset Value
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${currencyFmt.format(item.totalCostValue)} Ks',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navRailBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryName(ProductCategory cat) {
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
