import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../view_models/credit_ledger_notifier.dart';

class CreditLedgerTabView extends ConsumerWidget {
  const CreditLedgerTabView({super.key});

  void _showClearDebtDialog(
      BuildContext context, WidgetRef ref, CreditLedgerEntry entry) {
    final currencyFmt = NumberFormat('#,###');
    final paymentCtrl = TextEditingController(
      text: entry.balanceOutstanding.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.price_check_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Receive Credit Payment (အကြွေးဆပ်ငွေလက်ခံ)',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ဝယ်ယူသူ - ${entry.customerName}',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'ဘောက်ချာ - ${entry.voucherRef} • ဖုန်း - ${entry.customerPhone}',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navRailBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ကျန်ရှိနေသော အကြွေးကျန်ငွေ -',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    Text(
                      '${currencyFmt.format(entry.balanceOutstanding)} Ks',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ယခုလက်ခံမည့် ပမာဏ (ကျပ်) -',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: paymentCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  suffixText: 'Ks',
                  suffixStyle:
                      const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.border),
            ),
            child: const Text('မလုပ်တော့ပါ (Cancel)'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final amt = double.tryParse(paymentCtrl.text) ??
                  entry.balanceOutstanding;
              bool ok;
              if (amt >= entry.balanceOutstanding) {
                ok = await ref
                    .read(creditLedgerProvider.notifier)
                    .markAsPaid(entry.id);
              } else {
                ok = await ref
                    .read(creditLedgerProvider.notifier)
                    .recordPayment(entry.id, amt);
              }
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ဘောက်ချာ ${entry.voucherRef} အတွက် ${currencyFmt.format(amt)} ကျပ် လက်ခံရယူပြီးပါပြီ။',
                      ),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('ငွေလက်ခံမည် (Confirm)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd');
    final ledger = ref.watch(creditLedgerProvider);
    final entries = ledger.filteredEntries;

    return Column(
      children: [
        // ── Top Summary Cards ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _summaryCard(
                icon: Icons.assignment_outlined,
                title: 'အကြွေးအရောင်း စုစုပေါင်း (CREDIT SALES)',
                value: '${currencyFmt.format(ledger.totalDebtIncurred)} Ks',
                subtitle: 'အကြွေးမှတ်တမ်း ${ledger.entries.length} ခု',
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 14),

              _summaryCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'ပြန်လည်ရရှိပြီးငွေ (RECOVERED)',
                value: '${currencyFmt.format(ledger.totalPaidReceived)} Ks',
                subtitle: 'ကြွေးကျေပြီး ${ledger.clearedCount} မှု',
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),

              _summaryCard(
                icon: Icons.pending_actions_rounded,
                title: 'ကျန်ရှိအကြွေး စုစုပေါင်း (OUTSTANDING)',
                value: '${currencyFmt.format(ledger.totalOutstandingDebt)} Ks',
                subtitle: 'ဆပ်ရန်ကျန် ${ledger.unpaidCount} မှု',
                color: AppColors.error,
              ),
            ],
          ),
        ),

        // ── Search & Status Filters ───────────────────────────
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
                              .read(creditLedgerProvider.notifier)
                              .setSearchQuery(val),
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'ဝယ်ယူသူအမည်၊ ဖုန်း၊ ဘောက်ချာနံပါတ် ရှာဖွေပါ...',
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

              const SizedBox(width: 14),

              // Status Filter Pills
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _statusChip(
                      label: 'အားလုံး (${ledger.entries.length})',
                      selected: ledger.statusFilter == CreditLedgerFilterStatus.all,
                      onTap: () => ref
                          .read(creditLedgerProvider.notifier)
                          .setStatusFilter(CreditLedgerFilterStatus.all),
                    ),
                    _statusChip(
                      label: 'မဆပ်ရသေး (${ledger.unpaidCount})',
                      selected:
                          ledger.statusFilter == CreditLedgerFilterStatus.unpaid,
                      onTap: () => ref
                          .read(creditLedgerProvider.notifier)
                          .setStatusFilter(CreditLedgerFilterStatus.unpaid),
                      color: AppColors.error,
                    ),
                    _statusChip(
                      label: 'ကြွေးကျေ (${ledger.clearedCount})',
                      selected:
                          ledger.statusFilter == CreditLedgerFilterStatus.cleared,
                      onTap: () => ref
                          .read(creditLedgerProvider.notifier)
                          .setStatusFilter(CreditLedgerFilterStatus.cleared),
                      color: AppColors.primary,
                    ),
                  ],
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
              Expanded(
                flex: 3,
                child: Text('ဝယ်ယူသူအမည် (CUSTOMER)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 120,
                child: Text('ဖုန်းနံပါတ် (PHONE)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 140,
                child: Text('ဘောက်ချာ (REF)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 110,
                child: Text('ရက်စွဲ (DATE)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('အကြွေးစုစုပေါင်း (DEBT)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('ဆပ်ပြီးငွေ (PAID)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('ကျန်ရှိငွေ (BALANCE)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 90,
                child: Text('အခြေအနေ (STATUS)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 160,
                child: Text('လုပ်ဆောင်ချက် (ACTION)',
                    textAlign: TextAlign.center,
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
              final _ = await ref.refresh(remoteSalesProvider.future);
            },
            child: entries.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'အကြွေးမှတ်တမ်း မရှိပါ။',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: entries.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, thickness: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = entries[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          // Customer Name
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.customerName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.notes != null)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          // Phone
                          SizedBox(
                            width: 120,
                            child: Text(
                              item.customerPhone,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Voucher Ref
                          SizedBox(
                            width: 140,
                            child: Text(
                              item.voucherRef,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          // Date
                          SizedBox(
                            width: 110,
                            child: Text(
                              dateFmt.format(item.dateIncurred),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),

                          // Total Debt
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.totalDebt)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Paid Amount
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.paidAmount)} Ks',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Balance Outstanding
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${currencyFmt.format(item.balanceOutstanding)} Ks',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: item.isPaid
                                    ? AppColors.textMuted
                                    : AppColors.error,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Status
                          SizedBox(
                            width: 90,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.isPaid
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.isPaid
                                        ? AppColors.primary.withValues(alpha: 0.4)
                                        : AppColors.error.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  item.isPaid ? 'ကြွေးကျေ' : 'မဆပ်ရသေး',
                                  style: TextStyle(
                                    color: item.isPaid
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Action
                          SizedBox(
                            width: 160,
                            child: item.isPaid
                                ? const Center(
                                    child: Text(
                                      'ရှင်းပြီး ✅',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _showClearDebtDialog(
                                        context, ref, item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'ငွေလက်ခံမည် (ဆပ်မည်)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
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

  Widget _summaryCard({
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

  Widget _statusChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
