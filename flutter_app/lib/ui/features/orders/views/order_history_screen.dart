import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../pos/view_models/transaction_notifier.dart';
import '../../pos/widgets/receipt_dialog.dart';
import '../../settings/view_models/permission_group_notifier.dart';
import '../view_models/order_history_notifier.dart';
import '../widgets/order_detail_dialog.dart';
import '../../../shared/widgets/loading_view.dart';

/// Screen displaying completed orders & vouchers with default Today date filter
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key, this.onNavigateToPos});

  final VoidCallback? onNavigateToPos;

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(remoteSalesProvider);
    });
    _searchCtrl.addListener(() {
      ref
          .read(orderHistoryFilterProvider.notifier)
          .setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(orderHistoryFilterProvider.notifier)
          .setCustomDateRange(picked);
    }
  }

  void _confirmDeleteOrder(SaleTransaction sale) {
    final authState = ref.read(authProvider);
    final permissionGroups = ref.read(permissionGroupProvider);
    if (!(authState.currentUser?.canDeleteData(permissionGroups) ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'ဒေတာနှင့် မှတ်တမ်းများ ပယ်ဖျက်ခွင့် (Delete Permission) မရှိပါ။ Super Admin ထံ ခွင့်ပြုချက်တောင်းခံပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'ဘောက်ချာ ပယ်ဖျက်ရန် အတည်ပြုပါ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'ဘောက်ချာ #${sale.receiptNo} (${sale.totalAmount.toStringAsFixed(0)} Ks) ကို ပယ်ဖျက်ရန် သေချာပါသလား?\n\n'
          '⚠️ ဤဘောက်ချာတွင် ပါဝင်သော ကုန်ပစ္စည်းအရေအတွက်များအား ဆိုင်ခွဲလက်ကျန်စာရင်း (Stock) ထဲသို့ အလိုအလျောက် ပြန်လည်ဖြည့်သွင်းသွားမည်ဖြစ်ပါသည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('မလုပ်တော့ပါ (Cancel)',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(transactionProvider.notifier)
                    .deleteTransaction(sale.receiptNo);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'ဘောက်ချာ #${sale.receiptNo} ကို အောင်မြင်စွာ ပယ်ဖျက်ပြီး ပစ္စည်းလက်ကျန်များကို ပြန်လည်ဖြည့်သွင်းပြီးပါပြီ။'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ပယ်ဖျက်ခြင်း မအောင်မြင်ပါ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ပယ်ဖျက်မည် (Void Order)'),
          ),
        ],
      ),
    );
  }

  String _getDateFilterDisplay(OrderHistoryFilterState filter) {
    final now = DateTime.now();
    final dateFmt = DateFormat('MMM dd, yyyy');

    switch (filter.dateFilter) {
      case OrderDateFilter.today:
        return 'Today (${dateFmt.format(now)})';
      case OrderDateFilter.yesterday:
        return 'Yesterday (${dateFmt.format(now.subtract(const Duration(days: 1)))})';
      case OrderDateFilter.thisWeek:
        return 'Last 7 Days';
      case OrderDateFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case OrderDateFilter.allTime:
        return 'All Time History';
      case OrderDateFilter.custom:
        if (filter.customDateRange != null) {
          return '${dateFmt.format(filter.customDateRange!.start)} - ${dateFmt.format(filter.customDateRange!.end)}';
        }
        return 'Custom Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(orderHistoryFilterProvider);
    final filterNotifier = ref.read(orderHistoryFilterProvider.notifier);
    final orders = ref.watch(filteredOrderHistoryProvider);
    final summary = ref.watch(orderHistorySummaryProvider);
    final remoteSalesAsync = ref.watch(remoteSalesProvider);
    final isOrdersLoading = remoteSalesAsync.isLoading && orders.isEmpty;
    final authState = ref.watch(authProvider);
    final permissionGroups = ref.watch(permissionGroupProvider);
    final canDelete = authState.currentUser?.canDeleteData(permissionGroups) ?? false;
    final currencyFmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navRailBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'အရောင်းဘောက်ချာမှတ်တမ်း (Order History)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'အရောင်းနှင့် ငွေလက်ခံဖြတ်ပိုင်းမှတ်တမ်း • ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getDateFilterDisplay(filter),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.onNavigateToPos != null)
                  ElevatedButton.icon(
                    onPressed: widget.onNavigateToPos,
                    icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                    label: const Text(
                      'အရောင်းကောင်တာသို့ (POS)',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),

          // ── Date Preset Filters Bar (DEFAULT: TODAY) ───────────────
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
                  const Icon(Icons.calendar_today_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'ရက်စွဲရွေးချယ်မှု:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Preset Chips
                  _filterChip(
                    label: 'ယနေ့ (Today)',
                    isSelected: filter.dateFilter == OrderDateFilter.today,
                    onTap: () =>
                        filterNotifier.setDateFilter(OrderDateFilter.today),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'မနေ့က (Yesterday)',
                    isSelected: filter.dateFilter == OrderDateFilter.yesterday,
                    onTap: () =>
                        filterNotifier.setDateFilter(OrderDateFilter.yesterday),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'ဒီတစ်ပတ် (7 Days)',
                    isSelected: filter.dateFilter == OrderDateFilter.thisWeek,
                    onTap: () =>
                        filterNotifier.setDateFilter(OrderDateFilter.thisWeek),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'ဒီတစ်လ (Month)',
                    isSelected: filter.dateFilter == OrderDateFilter.thisMonth,
                    onTap: () =>
                        filterNotifier.setDateFilter(OrderDateFilter.thisMonth),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'အားလုံး (All Time)',
                    isSelected: filter.dateFilter == OrderDateFilter.allTime,
                    onTap: () =>
                        filterNotifier.setDateFilter(OrderDateFilter.allTime),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: filter.dateFilter == OrderDateFilter.custom &&
                            filter.customDateRange != null
                        ? 'စိတ်ကြိုက်: ${_getDateFilterDisplay(filter)}'
                        : 'ရက်စွဲစိတ်ကြိုက်... 📅',
                    isSelected: filter.dateFilter == OrderDateFilter.custom,
                    onTap: _pickCustomDateRange,
                  ),
                ],
              ),
            ),
          ),

          // ── Search & Secondary Filters Row ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText:
                            'ဘောက်ချာအမှတ်၊ ပစ္စည်းအမည် ရှာဖွေပါ...',
                        hintStyle: TextStyle(
                            color: AppColors.textMuted, fontSize: 11.5),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 17, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: _searchCtrl.clear,
                                child: Icon(Icons.close_rounded,
                                    size: 15, color: AppColors.textMuted),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Branch selector
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ['all', ...kBranches.keys].contains(filter.branchId)
                          ? filter.branchId
                          : 'all',
                      dropdownColor: AppColors.surface,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.textSecondary),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('ဆိုင်ခွဲအားလုံး (All Branches)'),
                        ),
                        ...kBranches.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) filterNotifier.setBranch(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Payment Method selector
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaymentMethodType?>(
                      value: filter.paymentMethod,
                      dropdownColor: AppColors.surface,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.textSecondary),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('ငွေချေမှုပုံစံအားလုံး'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodType.cash,
                          child: Text('💵 ငွေသား (Cash)'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodType.kpay,
                          child: Text('📱 KPay (ကေပေး)'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodType.wavePay,
                          child: Text('📱 WavePay (ဝေ့ဗ်)'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodType.credit,
                          child: Text('📋 အကြွေး (Credit)'),
                        ),
                      ],
                      onChanged: (val) {
                        filterNotifier.setPaymentMethod(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Reset button if filters active
                if (filter.dateFilter != OrderDateFilter.today ||
                    filter.branchId != 'all' ||
                    filter.paymentMethod != null ||
                    filter.searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      filterNotifier.resetFilters();
                    },
                    icon: Icon(Icons.refresh_rounded,
                        size: 14, color: AppColors.textMuted),
                    label: Text(
                      'ယနေ့သို့ ပြန်ထားမည်',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          // ── Summary KPI Metrics Bar ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.navRailBg,
            child: Row(
              children: [
                _kpiCard(
                  title: 'ဘောက်ချာအရေအတွက်',
                  value: '${summary.orderCount}',
                  icon: Icons.receipt_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'စုစုပေါင်းအရောင်း',
                  value: '${currencyFmt.format(summary.totalRevenue)} Ks',
                  icon: Icons.payments_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'ငွေသားအရောင်း',
                  value: '${currencyFmt.format(summary.cashRevenue)} Ks',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'ဒစ်ဂျစ်တယ် (KPay/Wave)',
                  value: '${currencyFmt.format(summary.digitalRevenue)} Ks',
                  icon: Icons.phone_android_rounded,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  title: 'အကြွေးရောင်းရငွေ',
                  value: '${currencyFmt.format(summary.creditRevenue)} Ks',
                  icon: Icons.history_edu_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),

          // ── Orders List / Data View ────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await ref.read(branchesProvider.notifier).loadBranches();
                final _ = await ref.refresh(remoteSalesProvider.future);
              },
              child: isOrdersLoading
                  ? const Center(
                      child: AppLoadingView(
                        message: 'အရောင်းဘောက်ချာ မှတ်တမ်းများ ရယူနေပါသည်...',
                        subMessage: 'Loading sales vouchers from database...',
                        icon: Icons.receipt_long_rounded,
                      ),
                    )
                  : orders.isEmpty
                      ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
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
                                  child: Icon(Icons.receipt_long_outlined,
                                      size: 44, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'ဘောက်ချာမှတ်တမ်း မရှိပါ',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ရွေးချယ်ထားသော စစ်ထုတ်ချက်အတွက် ဘောက်ချာမှတ်တမ်း မရှိသေးပါ။',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    filterNotifier.resetFilters();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                  ),
                                  child: const Text('Reset Date to Today (ယနေ့သို့ ပြန်ထားမည်)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final sale = orders[index];
                        return _OrderRowCard(
                          transaction: sale,
                          currencyFmt: currencyFmt,
                          canDelete: canDelete,
                          onViewDetails: () => OrderDetailDialog.show(
                            context,
                            sale,
                            onDelete: canDelete
                                ? () => _confirmDeleteOrder(sale)
                                : null,
                          ),
                          onReprint: () => showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.65),
                            builder: (_) =>
                                ReceiptDialog(transaction: sale),
                          ),
                          onDelete: canDelete
                              ? () => _confirmDeleteOrder(sale)
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
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
}

// ── Single Order Row / Card ──────────────────────────────────

class _OrderRowCard extends StatelessWidget {
  const _OrderRowCard({
    required this.transaction,
    required this.currencyFmt,
    required this.onViewDetails,
    required this.onReprint,
    this.canDelete = false,
    this.onDelete,
  });

  final SaleTransaction transaction;
  final NumberFormat currencyFmt;
  final VoidCallback onViewDetails;
  final VoidCallback onReprint;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a');
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Receipt Icon + Voucher No
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),

          // Voucher info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction.receiptNo,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildMiniBadge(transaction.paymentMethod),
                  ],
                ),
                const SizedBox(height: 3),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11.5, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFmt.format(transaction.createdAt)} (${dateFmt.format(transaction.createdAt)})',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Text('•',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text(
                        transaction.branchName,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cashier info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.badge_outlined,
                      size: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ငွေကိုင်',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                      Text(
                        transaction.cashierName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items summary
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.items.fold(0, (s, i) => s + i.quantity)} ခု: ${transaction.items.map((i) => "${i.productName} (×${i.quantity})").take(2).join(", ")}${transaction.items.length > 2 ? "..." : ""}',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Total Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${currencyFmt.format(transaction.totalAmount)} Ks',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (transaction.discountAmount > 0)
                  Text(
                    'လျှော့ငွေ ${currencyFmt.format(transaction.discountAmount)} Ks',
                    style: const TextStyle(
                        color: AppColors.warning, fontSize: 9.5),
                  ),
              ],
            ),
          ),

          // Action Buttons: Details & Reprint
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('အသေးစိတ်', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onReprint,
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text('ပြန်ထုတ်မည်', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (canDelete && onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  tooltip: 'ဘောက်ချာဖျက်မည် (Delete / Void Order)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(PaymentMethodType method) {
    final (bg, fg, label) = switch (method) {
      PaymentMethodType.cash => (
          AppColors.success.withValues(alpha: 0.15),
          AppColors.success,
          'ငွေသား'
        ),
      PaymentMethodType.kpay => (
          Colors.blue.withValues(alpha: 0.15),
          Colors.lightBlueAccent,
          'KPay'
        ),
      PaymentMethodType.wavePay => (
          Colors.orange.withValues(alpha: 0.15),
          Colors.orangeAccent,
          'Wave'
        ),
      PaymentMethodType.mobileBanking => (
          Colors.purple.withValues(alpha: 0.15),
          Colors.purpleAccent,
          'ဘဏ်'
        ),
      PaymentMethodType.credit => (
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning,
          'အကြွေး'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
