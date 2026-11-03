import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../pos/widgets/receipt_dialog.dart';

/// Modal dialog showing the itemized breakdown of a completed sale with reprint option
class OrderDetailDialog extends StatelessWidget {
  const OrderDetailDialog({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  final SaleTransaction transaction;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context,
    SaleTransaction transaction, {
    VoidCallback? onDelete,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => OrderDetailDialog(
        transaction: transaction,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd hh:mm a');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 780,
        height: 640,
        child: Column(
          children: [
            // ── Modal Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.navRailBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ဘောက်ချာ #${transaction.receiptNo}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentBadge(transaction.paymentMethod),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ထုတ်ပေးချိန်: ${dateFmt.format(transaction.createdAt)} • ${transaction.branchName}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Voucher Content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cashier, Branch & Payment Method Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _infoTile(
                              icon: Icons.badge_outlined,
                              label: 'ငွေကိုင် / ဝန်ထမ်း',
                              value: transaction.cashierName,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          Expanded(
                            child: _infoTile(
                              icon: Icons.store_outlined,
                              label: 'ဆိုင်ခွဲ',
                              value: transaction.branchName,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          Expanded(
                            child: _infoTile(
                              icon: Icons.payments_outlined,
                              label: 'ငွေချေမှုပုံစံ',
                              value: transaction.paymentMethodDisplay,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Items Table
                    Text(
                      'ဝယ်ယူထားသော ပစ္စည်းများ (Purchased Items)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.navRailBg,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(11)),
                              border: Border(
                                  bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text('ပစ္စည်းအမည်',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('နှုန်းထား',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('အရေအတွက်',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text('ကျသင့်ငွေ',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),

                          // Table Rows
                          ...transaction.items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: idx % 2 == 0
                                    ? Colors.transparent
                                    : AppColors.surface.withValues(alpha: 0.5),
                                border: idx < transaction.items.length - 1
                                    ? Border(
                                        bottom:
                                            BorderSide(color: AppColors.border))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        Text(
                                          _getCategoryEmoji(item.category),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (item.originType != null)
                                                Text(
                                                  _getOriginLabel(item.originType!),
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${currencyFmt.format(item.unitPrice)} Ks',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '×${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${currencyFmt.format(item.lineTotal)} Ks',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (item.discountPercent > 0)
                                          Text(
                                            '-${item.discountPercent.toStringAsFixed(0)}% Off',
                                            style: const TextStyle(
                                              color: AppColors.warning,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Totals & Payment Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navRailBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            'ကျသင့်ငွေခွဲ (Subtotal)',
                            '${currencyFmt.format(transaction.subtotal)} Ks',
                            AppColors.textSecondary,
                          ),
                          if (transaction.discountAmount > 0)
                            _summaryRow(
                              'ဘောက်ချာ လျှော့ငွေ (Discount)',
                              '-${currencyFmt.format(transaction.discountAmount)} Ks',
                              AppColors.warning,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.border),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'စုစုပေါင်း ပေးချေငွေ (TOTAL)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${currencyFmt.format(transaction.totalAmount)} Ks',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          if (transaction.isCash) ...[
                            const SizedBox(height: 8),
                            _summaryRow(
                              'ပေးချေငွေ (Tendered)',
                              '${currencyFmt.format(transaction.tenderedAmount)} Ks',
                              AppColors.textMuted,
                            ),
                            _summaryRow(
                              'ပြန်အမ်းငွေ (Change)',
                              '${currencyFmt.format(transaction.changeAmount)} Ks',
                              AppColors.success,
                            ),
                          ] else if (transaction.referenceId != null) ...[
                            const SizedBox(height: 6),
                            _summaryRow(
                              'ငွေလွှဲ အမှတ်အသား (Ref ID)',
                              transaction.referenceId!,
                              AppColors.textSecondary,
                            ),
                          ],
                          if (transaction.notes != null &&
                              transaction.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _summaryRow(
                              'မှတ်ချက် (Notes)',
                              transaction.notes!,
                              AppColors.textMuted,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Dialog Bottom Action Bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.navRailBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ပိတ်မည် (Close)'),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete!();
                      },
                      icon: const Icon(Icons.delete_forever_rounded,
                          size: 17, color: AppColors.error),
                      label: const Text(
                        'ဘောက်ချာ ပယ်ဖျက်မည် (Void Order)',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.65),
                        builder: (_) =>
                            ReceiptDialog(transaction: transaction),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'ဘောက်ချာပြန်ထုတ်မည် (Reprint Receipt)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(PaymentMethodType method) {
    final (bg, fg, label) = switch (method) {
      PaymentMethodType.cash => (
          AppColors.success.withValues(alpha: 0.15),
          AppColors.success,
          'Cash (ငွေသား)'
        ),
      PaymentMethodType.kpay => (
          Colors.blue.withValues(alpha: 0.15),
          Colors.lightBlueAccent,
          'KPay'
        ),
      PaymentMethodType.wavePay => (
          Colors.orange.withValues(alpha: 0.15),
          Colors.orangeAccent,
          'WavePay'
        ),
      PaymentMethodType.mobileBanking => (
          Colors.purple.withValues(alpha: 0.15),
          Colors.purpleAccent,
          'Mobile Banking'
        ),
      PaymentMethodType.credit => (
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning,
          'Credit (အကြွေး)'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getCategoryEmoji(ProductCategory category) => switch (category) {
        ProductCategory.plants => '🌱',
        ProductCategory.pots => '🪴',
        ProductCategory.chemicals => '🧪',
        ProductCategory.tools => '✂️',
        _ => '📦',
      };

  String _getOriginLabel(OriginType origin) => switch (origin) {
        OriginType.thaiImport => 'Thai Import',
        OriginType.chinaImport => 'China Import',
        OriginType.local => 'Local Origin',
      };
}
