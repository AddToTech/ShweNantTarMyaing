import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../wastage/view_models/wastage_notifier.dart';
import '../view_models/reports_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

class OverviewTabView extends ConsumerWidget {
  const OverviewTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(branchesProvider);
    final currencyFmt = NumberFormat('#,###');
    final reportsData = ref.watch(reportsDataProvider);
    final filter = ref.watch(reportsFilterProvider);
    final lowStockItems = ref.watch(lowStockAlertProvider(filter.branchId));

    return Column(
      children: [
        // ── Period & Branch Filter Sub-bar ─────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
              // Period Filter Pills
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ReportPeriod.values.map((p) {
                    final selected = filter.period == p;
                    return InkWell(
                      onTap: () => ref
                          .read(reportsFilterProvider.notifier)
                          .setPeriod(p),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 12),

              // Branch Filter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ['all', ...kBranches.keys].contains(filter.branchId)
                        ? filter.branchId
                        : 'all',
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('ဆိုင်ခွဲအားလုံး (All Branches)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      ...kBranches.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(reportsFilterProvider.notifier)
                            .setBranch(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'အစီရင်ခံကာလ - ${filter.period.label}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),

        // ── Scrollable Dashboard Body ─────────────────────────
        Expanded(
          child: (ref.watch(remoteSalesProvider).isLoading && reportsData.salesSummary.orderCount == 0)
              ? const Center(
                  child: AppLoadingView(
                    message: 'အစီရင်ခံစာ အချက်အလက်များ တွက်ချက်ရယူနေပါသည်...',
                    subMessage: 'Calculating reports data from database...',
                    icon: Icons.bar_chart_rounded,
                  ),
                )
              : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(catalogProvider.notifier).loadProducts(),
                ref.read(wastageProvider.notifier).loadWastage(),
              ]);
              final _ = await ref.refresh(remoteSalesProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. KPI Cards Row ──────────────────────────────
                Row(
                  children: [
                    // Gross Revenue
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.payments_rounded,
                        title: 'GROSS REVENUE (အရောင်းရငွေ)',
                        value:
                            '${currencyFmt.format(reportsData.salesSummary.grossRevenue)} Ks',
                        subtitle:
                            'ဘောက်ချာ ${reportsData.salesSummary.orderCount} စောင် • ပစ္စည်း ${reportsData.salesSummary.unitsCount} ခု',
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // COGS
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'COST OF GOODS (COGS)',
                        value:
                            '${currencyFmt.format(reportsData.salesSummary.totalCost)} Ks',
                        subtitle: 'ကုန်ပစ္စည်းဝယ်ယူမှု အရင်းစရိတ်',
                        accentColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Gross Profit & Margin
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.trending_up_rounded,
                        title: 'GROSS PROFIT (အသားတင်အမြတ်)',
                        value:
                            '${currencyFmt.format(reportsData.salesSummary.grossProfit)} Ks',
                        subtitle:
                            'အမြတ်ရာခိုင်နှုန်း ${reportsData.salesSummary.grossMargin.toStringAsFixed(1)}%',
                        accentColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Wastage Loss
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.eco_rounded,
                        title: 'WASTAGE LOSS (ပျက်စီးဆုံးရှုံးမှု)',
                        value:
                            '-${currencyFmt.format(reportsData.wastageSummary.totalLoss)} Ks',
                        subtitle:
                            'ပျက်စီးဆုံးရှုံးမှု ${reportsData.wastageSummary.totalQuantity} ခု',
                        accentColor: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // OPEX / Payroll Salaries
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.badge_rounded,
                        title: 'OPEX (လစာစရိတ်)',
                        value:
                            '-${currencyFmt.format(reportsData.operatingExpense)} Ks',
                        subtitle:
                            'လစာထုတ်ပေးမှု ${reportsData.payrollDisbursedCount} ကြိမ်',
                        accentColor: Colors.deepOrangeAccent,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Net Profit
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'NET PROFIT (ကျန်ရှိအမြတ်)',
                        value:
                            '${currencyFmt.format(reportsData.netProfit)} Ks',
                        subtitle:
                            'အသားတင်အမြတ် ${reportsData.netMargin.toStringAsFixed(1)}%',
                        accentColor: reportsData.netProfit >= 0
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── 2. Mid Section: Category Share & Wastage Loss ─
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Revenue Breakdown (60% width)
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pie_chart_rounded,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ကဏ္ဍအလိုက် အရောင်းနှင့် အမြတ်ငွေ (Category Breakdown)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'စုစုပေါင်း - ${currencyFmt.format(reportsData.salesSummary.grossRevenue)} Ks',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...reportsData.categorySummaries.map((cat) {
                              return _CategoryBar(
                                summary: cat,
                                currencyFmt: currencyFmt,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // Wastage Loss Breakdown (40% width)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delete_sweep_rounded,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'အပင်သေဆုံးနှင့် ပျက်စီးဆုံးရှုံးမှု (Wastage)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _WastageBreakdown(
                              summary: reportsData.wastageSummary,
                              currencyFmt: currencyFmt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── 3. Bottom Section: Low Stock & Restock Alert ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ပစ္စည်းပြတ်လပ်မှု သတိပေးချက် (Restock Alerts)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lowStockItems.isNotEmpty
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: lowStockItems.isNotEmpty
                                    ? AppColors.warning
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              '${lowStockItems.length} မျိုး လက်ကျန်နည်းနေသည်',
                              style: TextStyle(
                                color: lowStockItems.isNotEmpty
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LowStockAlerts(
                        items: lowStockItems,
                        currencyFmt: currencyFmt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// ── Private Reusable Presentation Widgets for Overview Tab ────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.summary,
    required this.currencyFmt,
  });

  final CategorySalesSummary summary;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    final pct = (summary.revenueShare / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  summary.categoryName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${summary.unitsSold} ခုရောင်းရ',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${currencyFmt.format(summary.revenue)} Ks',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${summary.margin.toStringAsFixed(1)}% အမြတ်)',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                switch (summary.category) {
                  ProductCategory.plants => AppColors.primary,
                  ProductCategory.pots => const Color(0xFFD97706),
                  ProductCategory.chemicals => const Color(0xFF2563EB),
                  ProductCategory.tools => const Color(0xFF9333EA),
                  _ => AppColors.textSecondary,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getReasonColor(WastageReasonOption reason) => switch (reason) {
      WastageReasonOption.deadWithered => const Color(0xFFEF4444),
      WastageReasonOption.pestInfestation => const Color(0xFFF59E0B),
      WastageReasonOption.brokenCracked => const Color(0xFF8B5CF6),
      WastageReasonOption.other => const Color(0xFF6B7280),
    };

class _WastageBreakdown extends StatelessWidget {
  const _WastageBreakdown({
    required this.summary,
    required this.currencyFmt,
  });

  final WastageReportSummary summary;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    if (summary.totalLoss == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'ယခုကာလအတွင်း ပျက်စီးဆုံးရှုံးမှု မှတ်တမ်းမရှိပါ 🎉',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: summary.lossByReason.entries.map((entry) {
        final reason = entry.key;
        final loss = entry.value;
        final share = summary.totalLoss > 0
            ? (loss / summary.totalLoss * 100)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getReasonColor(reason),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason.burmeseLabel,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                '-${currencyFmt.format(loss)} Ks',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '${share.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LowStockAlerts extends StatelessWidget {
  const _LowStockAlerts({
    required this.items,
    required this.currencyFmt,
  });

  final List<ProductWithStock> items;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'ကုန်ပစ္စည်းလက်ကျန်အားလုံး လုံလောက်မှုရှိပါသည်! ✅',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 88,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isOut = item.isOutOfStock;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOut
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              ProductAvatar(
                imageEmoji: item.product.imageEmoji,
                customImagePath: item.product.customImagePath,
                size: 24,
                fontSize: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.product.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kBranches[item.branchId] ?? item.branchId} • အနည်းဆုံး: ${item.product.minStock}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOut
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOut ? 'ပြတ်' : '${item.stock} ကျန်',
                  style: TextStyle(
                    color: isOut ? AppColors.error : AppColors.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
