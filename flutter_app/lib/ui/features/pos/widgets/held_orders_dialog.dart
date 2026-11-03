import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/cart_notifier.dart';

/// Modal dialog allowing cashiers to view, resume, or discard held orders
class HeldOrdersDialog extends ConsumerWidget {
  const HeldOrdersDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const HeldOrdersDialog(),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'ယခုလေးတင်';
    if (diff.inMinutes < 60) return '${diff.inMinutes} မိနစ် အရင်က';
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final heldOrders = cartState.heldOrders;
    final currencyFmt = NumberFormat('#,###');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 720,
        height: 580,
        child: Column(
          children: [
            // ── Dialog Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.navRailBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pause_circle_filled_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ဆိုင်းငံ့ထားသော အော်ဒါများ (Held Orders)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: heldOrders.isNotEmpty
                                    ? AppColors.warning.withValues(alpha: 0.2)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: heldOrders.isNotEmpty
                                      ? AppColors.warning.withValues(alpha: 0.5)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                '${heldOrders.length} ခု ဆိုင်းငံ့',
                                style: TextStyle(
                                  color: heldOrders.isNotEmpty
                                      ? AppColors.warning
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ဆိုင်းငံ့ထားသော အော်ဒါများ စာရင်း — ပြန်လည်ရောင်းချရန် Resume ကိုနှိပ်ပါ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Orders List or Empty State ─────────────────────────────
            Expanded(
              child: heldOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              Icons.pause_circle_outline_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ဆိုင်းငံ့ထားသော အော်ဒါမရှိပါ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'လက်ရှိဆိုင်းငံ့ထားသော အော်ဒါမရှိပါ။\nအော်ဒါကို ယာယီဆိုင်းငံ့ရန် Cart အောက်ခြေရှိ "Hold (ဆိုင်းငံ့)" ခလုတ်ကို နှိပ်ပါ။',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: heldOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = heldOrders[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ticket header & Time
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.receipt_rounded,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'အော်ဒါ #${order.ticketNumber}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.access_time_rounded,
                                      size: 13, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(order.heldAt),
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (order.customerName != null &&
                                      order.customerName!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.person_outline_rounded,
                                        size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.customerName!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text(
                                    '${currencyFmt.format(order.totalAmount)} Ks',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),

                              if (order.note != null &&
                                  order.note!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sticky_note_2_outlined,
                                          size: 12, color: AppColors.warning),
                                      const SizedBox(width: 6),
                                      Text(
                                        'မှတ်ချက်: ${order.note!}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // Items preview chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: order.items.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.border
                                              .withValues(alpha: 0.6)),
                                    ),
                                    child: Text(
                                      '${item.product.name} ×${item.quantity}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 14),
                              Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.border),
                              const SizedBox(height: 12),

                              // Actions Row: Discard & Resume
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 8,
                                spacing: 8,
                                children: [
                                  Text(
                                    '${order.itemCount} မျိုး',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Discard Button
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _confirmDiscard(context, ref, order);
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            size: 14),
                                        label: const Text('ပယ်ဖျက်မည်',
                                            style: TextStyle(fontSize: 11.5)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: BorderSide(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Resume Button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .resumeHeldOrder(order.id);
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.check_circle_rounded,
                                                      color: AppColors.success,
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'အော်ဒါ #${order.ticketNumber} ကို ခြင်းတောင်းထဲသို့ ပြန်လည်ထည့်သွင်းပြီးပါပြီ',
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.play_arrow_rounded,
                                            size: 16),
                                        label: const Text(
                                          'ဆက်လက်ရောင်းမည်',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textOnPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 7),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDiscard(
      BuildContext context, WidgetRef ref, HeldOrder order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(
              'ဆိုင်းငံ့အော်ဒါကို ပယ်ဖျက်မလား?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'အော်ဒါ #${order.ticketNumber} (${order.itemCount} မျိုး) ကို ဆိုင်းငံ့စာရင်းမှ အပြီးပယ်ဖျက်ပါမည်။',
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
              ref.read(cartProvider.notifier).discardHeldOrder(order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ပယ်ဖျက်မည်'),
          ),
        ],
      ),
    );
  }
}
