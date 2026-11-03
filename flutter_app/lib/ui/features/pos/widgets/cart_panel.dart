import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/cart_notifier.dart';
import 'cart_item_tile.dart';
import 'held_orders_dialog.dart';

// ============================================================
// CartPanel — right-side order panel (35% width)
// ============================================================

class CartPanel extends ConsumerWidget {
  const CartPanel({
    super.key,
    required this.onCheckout,
    required this.onHold,
  });

  final VoidCallback onCheckout;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart     = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          _CartHeader(
            ticketNo:  cart.ticketNumber,
            itemCount: cart.itemCount,
            heldCount: cart.heldOrders.length,
            onClear:   notifier.clear,
          ),

          // ── Cart items ────────────────────────────────────
          Expanded(
            child: cart.isEmpty
                ? _EmptyCartPlaceholder(heldCount: cart.heldOrders.length)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) =>
                        CartItemTile(item: cart.items[i]),
                  ),
          ),

          // ── Order-level discount ──────────────────────────
          if (!cart.isEmpty)
            _OrderDiscountRow(
              current:   cart.orderDiscountAmount,
              subtotal:  cart.subtotal,
              onChanged: notifier.setOrderDiscount,
            ),

          Divider(height: 1, thickness: 1, color: AppColors.divider),

          // ── Summary ───────────────────────────────────────
          _OrderSummary(cart: cart),

          Divider(height: 1, thickness: 1, color: AppColors.divider),

          // ── Action buttons ────────────────────────────────
          _ActionButtons(
            enabled:    !cart.isEmpty,
            onHold:     onHold,
            onCheckout: onCheckout,
          ),
        ],
      ),
    );
  }
}

// ── Cart header ───────────────────────────────────────────

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.ticketNo,
    required this.itemCount,
    required this.heldCount,
    required this.onClear,
  });
  final String ticketNo;
  final int    itemCount;
  final int    heldCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navRailBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ဘောက်ချာ #$ticketNo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ပစ္စည်း $itemCount မျိုး ထည့်ထားသည်',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Held orders badge button if any
          if (heldCount > 0) ...[
            GestureDetector(
              onTap: () => HeldOrdersDialog.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded,
                        color: AppColors.warning, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'ဆိုင်းငံ့ ($heldCount)',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (itemCount > 0)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'ရှင်းမည် (Clear)',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty cart ────────────────────────────────────────────

class _EmptyCartPlaceholder extends StatelessWidget {
  const _EmptyCartPlaceholder({this.heldCount = 0});
  final int heldCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text('ခြင်းတောင်းထဲတွင် ပစ္စည်းမရှိပါ',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('ပစ္စည်းထည့်ရန် ကုန်ပစ္စည်းကို နှိပ်ပါ',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          if (heldCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pause_circle_filled_rounded,
                          size: 15, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'ဆိုင်းငံ့ထားသော အော်ဒါ $heldCount ခု ရှိသည်',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => HeldOrdersDialog.show(context),
                    icon: const Icon(Icons.restore_rounded, size: 14),
                    label: const Text('ဖွင့်ကြည့်မည် (View Held)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Order-level discount row ──────────────────────────────

class _OrderDiscountRow extends StatefulWidget {
  const _OrderDiscountRow({
    required this.current,
    required this.subtotal,
    required this.onChanged,
  });
  final double current;
  final double subtotal;
  final ValueChanged<double> onChanged;

  @override
  State<_OrderDiscountRow> createState() => _OrderDiscountRowState();
}

class _OrderDiscountRowState extends State<_OrderDiscountRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined,
              size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text('ဘောက်ချာ လျှော့ငွေ:',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          const Spacer(),
          if (widget.current > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '(-${fmt.format(widget.current)} Ks)',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          SizedBox(
            width: 96,
            height: 30,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 11),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                hintText: '0 ကျပ်',
                hintStyle: TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
              onSubmitted: (val) {
                final amount =
                    double.tryParse(val.replaceAll(',', '')) ?? 0;
                widget.onChanged(amount);
                _ctrl.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order summary ─────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          _SummaryRow(
            label: 'ကျသင့်ငွေခွဲ (Subtotal)',
            value: '${fmt.format(cart.subtotal)} Ks',
            valueColor: AppColors.textSecondary,
          ),
          if (cart.orderDiscountAmount > 0)
            _SummaryRow(
              label: 'လျှော့ငွေ (Discount)',
              value: '(-${fmt.format(cart.orderDiscountAmount)}) Ks',
              valueColor: AppColors.warning,
            ),
          if (cart.taxAmount > 0)
            _SummaryRow(
              label: 'အခွန် (Tax)',
              value: '${fmt.format(cart.taxAmount)} Ks',
              valueColor: AppColors.textSecondary,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'စုစုပေါင်း (TOTAL)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${fmt.format(cart.totalAmount)} Ks',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.enabled,
    required this.onHold,
    required this.onCheckout,
  });
  final bool enabled;
  final VoidCallback onHold;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          // Hold Order
          Expanded(
            flex: 2,
            child: _ActionBtn(
              label: 'ဆိုင်းငံ့ (Hold)',
              icon: Icons.pause_circle_outline_rounded,
              enabled: enabled,
              isPrimary: false,
              onTap: onHold,
            ),
          ),
          const SizedBox(width: 10),
          // Checkout
          Expanded(
            flex: 3,
            child: _ActionBtn(
              label: 'ငွေရှင်းမည် (Pay)',
              icon: Icons.payment_rounded,
              enabled: enabled,
              isPrimary: true,
              onTap: onCheckout,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          gradient: (isPrimary && enabled)
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark])
              : null,
          color: (!isPrimary)
              ? (enabled ? AppColors.surfaceVariant : AppColors.surface)
              : (enabled ? null : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? (enabled ? AppColors.primary : AppColors.border)
                : (enabled ? AppColors.borderLight : AppColors.border),
          ),
          boxShadow: (isPrimary && enabled)
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: _iconColor(enabled, isPrimary),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _iconColor(enabled, isPrimary),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(bool enabled, bool isPrimary) {
    if (!enabled) return AppColors.textMuted;
    if (isPrimary) return AppColors.textOnPrimary;
    return AppColors.textSecondary;
  }
}
