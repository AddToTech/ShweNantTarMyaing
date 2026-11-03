import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../orders/widgets/order_detail_dialog.dart';
import '../view_models/sales_transactions_report_notifier.dart';

class SalesTransactionsTabView extends ConsumerStatefulWidget {
  const SalesTransactionsTabView({super.key});

  @override
  ConsumerState<SalesTransactionsTabView> createState() =>
      _SalesTransactionsTabViewState();
}

class _SalesTransactionsTabViewState
    extends ConsumerState<SalesTransactionsTabView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme:
                DialogThemeData(backgroundColor: AppColors.surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(salesReportFilterProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final timeFmt = DateFormat('hh:mm a');
    final dateFmt = DateFormat('yyyy-MM-dd');

    final filter = ref.watch(salesReportFilterProvider);
    final reportData = ref.watch(salesTransactionsReportProvider);

    return Column(
      children: [
        // ── Filter Bar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Date Chips
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dateChip(
                      label: 'Today (ယနေ့)',
                      selected: filter.dateFilter == SalesReportDateFilter.today,
                      onTap: () => ref
                          .read(salesReportFilterProvider.notifier)
                          .setDateFilter(SalesReportDateFilter.today),
                    ),
                    _dateChip(
                      label: 'Yesterday (မနေ့က)',
                      selected: filter.dateFilter == SalesReportDateFilter.yesterday,
                      onTap: () => ref
                          .read(salesReportFilterProvider.notifier)
                          .setDateFilter(SalesReportDateFilter.yesterday),
                    ),
                    _dateChip(
                      label: 'This Month (ဒီလ)',
                      selected: filter.dateFilter == SalesReportDateFilter.thisMonth,
                      onTap: () => ref
                          .read(salesReportFilterProvider.notifier)
                          .setDateFilter(SalesReportDateFilter.thisMonth),
                    ),
                    _dateChip(
                      label: filter.dateFilter == SalesReportDateFilter.custom &&
                              filter.customStartDate != null &&
                              filter.customEndDate != null
                          ? '${dateFmt.format(filter.customStartDate!)} - ${dateFmt.format(filter.customEndDate!)}'
                          : 'စိတ်ကြိုက်ရက်စွဲ (Custom)...',
                      selected: filter.dateFilter == SalesReportDateFilter.custom,
                      onTap: _pickCustomRange,
                      icon: Icons.date_range_rounded,
                    ),
                  ],
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
                          controller: _searchCtrl,
                          onChanged: (val) => ref
                              .read(salesReportFilterProvider.notifier)
                              .setSearchQuery(val),
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'ဘောက်ချာအမှတ်၊ ငွေကိုင်၊ ပစ္စည်း ရှာဖွေပါ...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted, fontSize: 11.5),
                            border: InputBorder.none,
                            isDense: true,
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      ref
                                          .read(salesReportFilterProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                    child: Icon(Icons.close_rounded,
                                        size: 14, color: AppColors.textMuted),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Branch Selector
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
                    value: ['all', ...kBranches.keys].contains(filter.branchId)
                        ? filter.branchId
                        : 'all',
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('ဆိုင်ခွဲအားလုံး (All Branches)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      ...kBranches.entries.map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12)),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(salesReportFilterProvider.notifier)
                            .setBranch(val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Payment Method Selector
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
                    value: filter.paymentMethod,
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('ငွေချေမှုအားလုံး (All)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('ငွေသား (Cash)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'kpay',
                        child: Text('KPay',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'wavePay',
                        child: Text('WavePay',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'credit',
                        child: Text('အကြွေး (Credit)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(salesReportFilterProvider.notifier)
                            .setPaymentMethod(val);
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
              SizedBox(
                  width: 150,
                  child: Text('ဘောက်ချာအမှတ် (VOUCHER)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 150,
                  child: Text('ရက်စွဲ/အချိန် (DATE)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 140,
                  child: Text('ဆိုင်ခွဲ (BRANCH)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 140,
                  child: Text('ငွေကိုင် (CASHIER)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 90,
                  child: Text('ပစ္စည်း (ITEMS)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 110,
                  child: Text('ငွေချေမှု (PAY)',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('ကျသင့်ငွေခွဲ (SUBTOTAL)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 100,
                  child: Text('လျှော့ငွေ (DISCOUNT)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 130,
                  child: Text('စုစုပေါင်း (TOTAL)',
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
              await ref.read(branchesProvider.notifier).loadBranches();
              final _ = await ref.refresh(remoteSalesProvider.future);
            },
            child: reportData.transactions.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No transactions found for this filter',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'စစ်ထုတ်ချက်နှင့် ကိုက်ညီသော အရောင်းမှတ်တမ်း မရှိပါ။',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: reportData.transactions.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, thickness: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final t = reportData.transactions[index];
                    final totalItems =
                        t.items.fold(0, (acc, item) => acc + item.quantity);

                    return InkWell(
                      onTap: () => OrderDetailDialog.show(context, t),
                      hoverColor: AppColors.primary.withValues(alpha: 0.05),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 13),
                        child: Row(
                          children: [
                            // Voucher No
                            SizedBox(
                              width: 150,
                              child: Text(
                                t.receiptNo,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Date & Time
                            SizedBox(
                              width: 150,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dateFmt.format(t.createdAt),
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    timeFmt.format(t.createdAt),
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),

                            // Branch
                            SizedBox(
                              width: 140,
                              child: Text(
                                t.branchName,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Cashier
                            SizedBox(
                              width: 140,
                              child: Text(
                                t.cashierName,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Items count
                            SizedBox(
                              width: 90,
                              child: Text(
                                '$totalItems',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),

                            // Payment Method Badge
                            SizedBox(
                              width: 110,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _paymentBadge(t.paymentMethod),
                              ),
                            ),

                            // Subtotal
                            Expanded(
                              child: Text(
                                '${currencyFmt.format(t.subtotal)} Ks',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ),

                            // Discount
                            SizedBox(
                              width: 100,
                              child: Text(
                                t.discountAmount > 0
                                    ? '-${currencyFmt.format(t.discountAmount)} Ks'
                                    : '-',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: t.discountAmount > 0
                                      ? AppColors.warning
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            // Grand Total
                            SizedBox(
                              width: 130,
                              child: Text(
                                '${currencyFmt.format(t.totalAmount)} Ks',
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
                'စုစုပေါင်း ဘောက်ချာ ${reportData.totalOrders} စောင်',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Cash Collected
              _footerMetric(
                label: 'ငွေသား (Cash)',
                value: '${currencyFmt.format(reportData.totalCash)} Ks',
                color: AppColors.primary,
              ),
              const SizedBox(width: 24),

              // Digital Pay
              _footerMetric(
                label: 'ဒီဂျစ်တယ် (KPay/Wave)',
                value: '${currencyFmt.format(reportData.totalDigital)} Ks',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 24),

              // Total Credit
              _footerMetric(
                label: 'အကြွေး (Credit)',
                value: '${currencyFmt.format(reportData.totalCredit)} Ks',
                color: AppColors.warning,
              ),
              const SizedBox(width: 24),

              // Total Net Sales
              _footerMetric(
                label: 'စုစုပေါင်း အရောင်းရငွေ (NET SALES)',
                value: '${currencyFmt.format(reportData.totalNetSales)} Ks',
                color: AppColors.accent,
                isLarge: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBadge(PaymentMethodType method) {
    final (label, color) = switch (method) {
      PaymentMethodType.cash => ('ငွေသား (Cash)', AppColors.primary),
      PaymentMethodType.kpay => ('KPay', const Color(0xFF0070F3)),
      PaymentMethodType.wavePay => ('WavePay', const Color(0xFFF59E0B)),
      PaymentMethodType.mobileBanking => ('ဘဏ်လွှဲ (Banking)', const Color(0xFF8B5CF6)),
      PaymentMethodType.credit => ('အကြွေး (Credit)', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _footerMetric({
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
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
            fontSize: isLarge ? 15 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
