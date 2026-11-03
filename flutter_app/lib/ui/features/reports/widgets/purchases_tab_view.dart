// ============================================================
// PurchasesTabView — အဝယ်စာရင်း အစီရင်ခံစာ (Purchases Report)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../purchases/view_models/purchase_notifier.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../../purchases/views/purchase_screen.dart';
import '../view_models/purchases_report_notifier.dart';

enum _PurchasesViewSection {
  vouchers,
  byVendor,
  byCategory,
}

class PurchasesTabView extends ConsumerStatefulWidget {
  const PurchasesTabView({super.key});

  @override
  ConsumerState<PurchasesTabView> createState() => _PurchasesTabViewState();
}

class _PurchasesTabViewState extends ConsumerState<PurchasesTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  _PurchasesViewSection _section = _PurchasesViewSection.vouchers;

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
            dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(purchasesReportFilterProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd');
    final filter = ref.watch(purchasesReportFilterProvider);
    final reportData = ref.watch(purchasesReportDataProvider);
    final vendors = ref.watch(activeVendorsProvider);

    return Column(
      children: [
        // ── Filter Toolbar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Filter Pills
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
                        label: 'All Time (အားလုံး)',
                        selected: filter.dateFilter ==
                            PurchasesReportDateFilter.allTime,
                        onTap: () => ref
                            .read(purchasesReportFilterProvider.notifier)
                            .setDateFilter(PurchasesReportDateFilter.allTime),
                      ),
                      _dateChip(
                        label: 'Today (ယနေ့)',
                        selected:
                            filter.dateFilter == PurchasesReportDateFilter.today,
                        onTap: () => ref
                            .read(purchasesReportFilterProvider.notifier)
                            .setDateFilter(PurchasesReportDateFilter.today),
                      ),
                      _dateChip(
                        label: 'Yesterday (မနေ့က)',
                        selected: filter.dateFilter ==
                            PurchasesReportDateFilter.yesterday,
                        onTap: () => ref
                            .read(purchasesReportFilterProvider.notifier)
                            .setDateFilter(PurchasesReportDateFilter.yesterday),
                      ),
                      _dateChip(
                        label: 'This Week (ဒီအပတ်)',
                        selected: filter.dateFilter ==
                            PurchasesReportDateFilter.thisWeek,
                        onTap: () => ref
                            .read(purchasesReportFilterProvider.notifier)
                            .setDateFilter(PurchasesReportDateFilter.thisWeek),
                      ),
                      _dateChip(
                        label: 'This Month (ဒီလ)',
                        selected: filter.dateFilter ==
                            PurchasesReportDateFilter.thisMonth,
                        onTap: () => ref
                            .read(purchasesReportFilterProvider.notifier)
                            .setDateFilter(PurchasesReportDateFilter.thisMonth),
                      ),
                      _dateChip(
                        label: filter.dateFilter ==
                                    PurchasesReportDateFilter.custom &&
                                filter.customStartDate != null &&
                                filter.customEndDate != null
                            ? '${dateFmt.format(filter.customStartDate!)} - ${dateFmt.format(filter.customEndDate!)}'
                            : 'Custom...',
                        selected: filter.dateFilter ==
                            PurchasesReportDateFilter.custom,
                        onTap: _pickCustomRange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Branch Filter Dropdown
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
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('ဆိုင်ခွဲအားလုံး (All Branches)',
                              style: TextStyle(fontSize: 12)),
                        ),
                        ...kBranches.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child:
                                  Text(e.value, style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(purchasesReportFilterProvider.notifier)
                              .setBranch(val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Payment Status Filter Dropdown
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
                      value: filter.paymentStatus,
                      dropdownColor: AppColors.surfaceVariant,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.primary),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('ငွေပေးချေမှု အားလုံး',
                              style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text('ငွေကြေ (Paid)',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.success)),
                        ),
                        DropdownMenuItem(
                          value: 'partial',
                          child: Text('တစ်စိတ်ပေး (Partial)',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.warning)),
                        ),
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('အကြွေး (Unpaid)',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.error)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(purchasesReportFilterProvider.notifier)
                              .setPaymentStatus(val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Vendor Filter Dropdown
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
                      value: filter.vendorId,
                      dropdownColor: AppColors.surfaceVariant,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.primary),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('ကုန်သည် အားလုံး (All Vendors)',
                              style: TextStyle(fontSize: 12)),
                        ),
                        ...vendors.map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(v.name,
                                  style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(purchasesReportFilterProvider.notifier)
                              .setVendor(val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Search Box
                SizedBox(
                  width: 200,
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => ref
                        .read(purchasesReportFilterProvider.notifier)
                        .setSearchQuery(val),
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ဘောင်ချာ / ကုန်သည် ရှာရန်...',
                      hintStyle: TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 16, color: AppColors.primary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(purchasesReportFilterProvider.notifier)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Main Body with KPI Cards & Content ──────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(purchaseProvider.notifier).loadPurchases(),
                ref.read(vendorProvider.notifier).loadVendors(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KPI Summary Cards ──────────────────────────────
                  Row(
                  children: [
                    // Card 1: Total Purchases
                    Expanded(
                      child: _kpiCard(
                        title: 'GROSS PURCHASES (စုစုပေါင်း ဝယ်ယူမှု)',
                        value: '${currencyFmt.format(reportData.totalPurchases)} Ks',
                        subtext:
                            '${reportData.totalInvoices} ဘောင်ချာ • ${reportData.totalItemsCount.toInt()} ခု',
                        icon: Icons.shopping_bag_rounded,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card 2: Total Paid
                    Expanded(
                      child: _kpiCard(
                        title: 'PAID AMOUNT (ရှင်းပြီး ငွေပမာဏ)',
                        value: '${currencyFmt.format(reportData.totalPaid)} Ks',
                        subtext:
                            '${reportData.paidPercentage.toStringAsFixed(1)}% ရှင်းပြီး',
                        icon: Icons.check_circle_rounded,
                        accentColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card 3: Outstanding Payables
                    Expanded(
                      child: _kpiCard(
                        title: 'OUTSTANDING DUE (ပေးရန်ကျန် အကြွေး)',
                        value:
                            '${currencyFmt.format(reportData.totalOutstanding)} Ks',
                        subtext: reportData.totalOutstanding > 0
                            ? 'ပေးချေရန် ကျန်ရှိနေသေးသည်'
                            : 'ကြွေးကျန် မရှိပါ',
                        icon: Icons.pending_actions_rounded,
                        accentColor: reportData.totalOutstanding > 0
                            ? AppColors.error
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card 4: Suppliers Count
                    Expanded(
                      child: _kpiCard(
                        title: 'SUPPLIERS (ကုန်သည် အရေအတွက်)',
                        value: '${reportData.vendorSummaries.length} ဦး',
                        subtext: 'ပစ္စည်းသွင်းကုန်သည် အရေအတွက်',
                        icon: Icons.storefront_rounded,
                        accentColor: const Color(0xFF64B5F6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Section Selector Pills ──────────────────────────
                Row(
                  children: [
                    _sectionPill(
                      icon: Icons.receipt_long_rounded,
                      label: 'အဝယ်ဘောင်ချာများ (${reportData.purchases.length})',
                      selected: _section == _PurchasesViewSection.vouchers,
                      onTap: () => setState(
                          () => _section = _PurchasesViewSection.vouchers),
                    ),
                    const SizedBox(width: 8),
                    _sectionPill(
                      icon: Icons.business_rounded,
                      label:
                          'ကုန်သည်အလိုက် (${reportData.vendorSummaries.length})',
                      selected: _section == _PurchasesViewSection.byVendor,
                      onTap: () => setState(
                          () => _section = _PurchasesViewSection.byVendor),
                    ),
                    const SizedBox(width: 8),
                    _sectionPill(
                      icon: Icons.category_rounded,
                      label:
                          'ပစ္စည်းကဏ္ဍအလိုက် (${reportData.categorySummaries.length})',
                      selected: _section == _PurchasesViewSection.byCategory,
                      onTap: () => setState(
                          () => _section = _PurchasesViewSection.byCategory),
                    ),
                    const Spacer(),
                    Text(
                      'စာရင်းစုစုပေါင်း ${reportData.purchases.length} ခု တွေ့ရှိပါသည်',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Section Body ────────────────────────────────────
                switch (_section) {
                  _PurchasesViewSection.vouchers =>
                    _buildVouchersTable(reportData, currencyFmt, dateFmt),
                  _PurchasesViewSection.byVendor =>
                    _buildVendorsView(reportData, currencyFmt),
                  _PurchasesViewSection.byCategory =>
                    _buildCategoryView(reportData, currencyFmt),
                },
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  // ── Date chip helper ──────────────────────────────────────────────
  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── KPI Card helper ───────────────────────────────────────────────
  Widget _kpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              color: accentColor == AppColors.error
                  ? AppColors.error
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Pill button ───────────────────────────────────────────
  Widget _sectionPill({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Vouchers Table View ────────────────────────────────────────
  Widget _buildVouchersTable(
    PurchasesReportData data,
    NumberFormat currencyFmt,
    DateFormat dateFmt,
  ) {
    if (data.purchases.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'ရွေးချယ်ထားသော အချက်အလက်များနှင့် ကိုက်ညီသော အဝယ်စာရင်း မရှိပါ',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'ရက်စွဲ သို့မဟုတ် Filter များကို ပြောင်းလဲရှာဖွေကြည့်ပါ',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text('ဘောင်ချာနံပါတ်',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 100,
                  child: Text('ရက်စွဲ',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('ကုန်သည် / မှတ်ချက်',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ဆိုင်ခွဲ',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('ပစ္စည်းအရေ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 120,
                  child: Text('ကျသင့်ငွေ (Ks)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 110,
                  child: Text('ရှင်းပြီး (Ks)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 110,
                  child: Text('ကျန်ငွေ (Ks)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 120,
                  child: Text('အခြေအနေ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.purchases.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.border),
            itemBuilder: (ctx, index) {
              final p = data.purchases[index];
              final statusColor = switch (p.paymentStatus) {
                PurchasePaymentStatus.paid => AppColors.success,
                PurchasePaymentStatus.partial => AppColors.warning,
                PurchasePaymentStatus.unpaid => AppColors.error,
              };

              return InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => PurchaseDetailDialog(
                    purchaseId: p.id,
                    initialPurchase: p,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Voucher No
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_rounded,
                                size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                p.purchaseNo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date
                      SizedBox(
                        width: 100,
                        child: Text(
                          dateFmt.format(p.purchaseDate),
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),

                      // Vendor & Notes
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.vendorName ?? '— မသတ်မှတ်ထားပါ',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.notes != null && p.notes!.isNotEmpty)
                              Text(
                                p.notes!,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      // Branch
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.branchLabel,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Items quantity count
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${p.items.fold<double>(0, (s, i) => s + i.quantity).toInt()} ခု',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Total Amount
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${currencyFmt.format(p.totalAmount)} Ks',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // Paid Amount
                      SizedBox(
                        width: 110,
                        child: Text(
                          '${currencyFmt.format(p.paidAmount)} Ks',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),

                      // Balance Due
                      SizedBox(
                        width: 110,
                        child: Text(
                          p.balanceDue > 0
                              ? '${currencyFmt.format(p.balanceDue)} Ks'
                              : '—',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: p.balanceDue > 0
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ),
                      ),

                      // Payment Status Badge
                      SizedBox(
                        width: 120,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              p.paymentStatus.burmeseLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // View Detail Button
                      SizedBox(
                        width: 60,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.primary),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => PurchaseDetailDialog(
                              purchaseId: p.id,
                              initialPurchase: p,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 2. Vendors Summary View ───────────────────────────────────────
  Widget _buildVendorsView(
      PurchasesReportData data, NumberFormat currencyFmt) {
    if (data.vendorSummaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Text('ကုန်သည်အလိုက် စာရင်းမရှိပါ',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        itemCount: data.vendorSummaries.length,
        itemBuilder: (ctx, index) {
          final v = data.vendorSummaries[index];
          final hasDebt = v.totalOutstanding > 0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasDebt
                    ? AppColors.warning.withValues(alpha: 0.35)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.vendorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            v.phone ?? 'ဖုန်းနံပါတ်မရှိ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${v.invoiceCount} ဘောင်ချာ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Metrics row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ဝယ်ယူမှု စုစုပေါင်း',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${currencyFmt.format(v.totalPurchased)} Ks',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ရှင်းပြီး ငွေ',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${currencyFmt.format(v.totalPaid)} Ks',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ပေးရန်ကျန် အကြွေး',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            hasDebt
                                ? '${currencyFmt.format(v.totalOutstanding)} Ks'
                                : '— ကြွေးကျန်မရှိ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasDebt
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress Bar of Payment Ratio
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (v.paidPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      v.paidPercentage >= 100
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ── 3. Category Breakdown View ────────────────────────────────────
  Widget _buildCategoryView(
      PurchasesReportData data, NumberFormat currencyFmt) {
    if (data.categorySummaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Text('ပစ္စည်းကဏ္ဍအလိုက် အဝယ်စာရင်း မရှိပါ',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Column(
      children: data.categorySummaries.map((cat) {
        final iconEmoji = switch (cat.category) {
          ProductCategory.plants => '🌿',
          ProductCategory.pots => '🏺',
          ProductCategory.chemicals => '🧪',
          ProductCategory.tools => '✂️',
          ProductCategory.others => '📦',
          ProductCategory.all => '🏷️',
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(iconEmoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.categoryName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'စုစုပေါင်း ဝယ်ယူအရေအတွက်: ${cat.totalQuantity.toInt()} ခု',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currencyFmt.format(cat.totalAmount)} Ks',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${cat.percentageShare.toStringAsFixed(1)}% ဝေစု',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (cat.percentageShare / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
