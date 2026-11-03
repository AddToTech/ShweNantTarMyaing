import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../view_models/cart_notifier.dart';

// ============================================================
// CartItemTile — a single line item in the cart panel
// ============================================================

class CartItemTile extends ConsumerStatefulWidget {
  const CartItemTile({super.key, required this.item});
  final CartItem item;

  @override
  ConsumerState<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<CartItemTile> {
  bool _showDiscountInput = false;
  final _discCtrl = TextEditingController();

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final pct = double.tryParse(_discCtrl.text) ?? 0.0;
    ref.read(cartProvider.notifier).setItemDiscount(widget.item.product.id, pct);
    setState(() => _showDiscountInput = false);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(cartProvider.notifier);
    final item     = widget.item;
    final fmt      = NumberFormat('#,###');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: emoji + name + delete ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: ProductAvatar(
                    imageEmoji: item.product.imageEmoji,
                    customImagePath: item.product.customImagePath,
                    size: 32,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Name + unit price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${fmt.format(item.unitPrice)} Ks / unit',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete
              GestureDetector(
                onTap: () => notifier.remove(item.product.id),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Row 2: stepper + discount toggle + line total ─
          Row(
            children: [
              // Quantity stepper
              _QuantityStepper(
                quantity: item.quantity,
                onDecrement: () => notifier.decrement(item.product.id),
                onIncrement: () => notifier.increment(item.product.id),
              ),

              const SizedBox(width: 8),

              // Discount badge / toggle
              GestureDetector(
                onTap: () => setState(
                    () => _showDiscountInput = !_showDiscountInput),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.discountPct > 0
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.discountPct > 0
                          ? AppColors.warning.withValues(alpha: 0.55)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    item.discountPct > 0
                        ? '-${item.discountPct.toStringAsFixed(0)}%'
                        : '% Disc',
                    style: TextStyle(
                      color: item.discountPct > 0
                          ? AppColors.warning
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Line total
              Text(
                '${fmt.format(item.lineTotal)} Ks',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // ── Discount input (collapsible) ──────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _showDiscountInput
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          'Discount %:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 72,
                          height: 30,
                          child: TextField(
                            controller: _discCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            autofocus: true,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                              hintText:
                                  item.discountPct.toStringAsFixed(0),
                              hintStyle: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                              suffixText: '%',
                              suffixStyle: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10),
                            ),
                            onSubmitted: (_) => _applyDiscount(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Apply button
                        GestureDetector(
                          onTap: _applyDiscount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Btn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Btn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 28, height: 28,
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
