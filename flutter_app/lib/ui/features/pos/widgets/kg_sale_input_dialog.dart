import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../view_models/cart_notifier.dart';
import '../view_models/pos_filter_notifier.dart';

/// Modal dialog asking the cashier for sold weight (Kg) and approximate piece count
/// when selling items from the "Kg အရောင်း" category in POS.
class KgSaleInputDialog extends ConsumerStatefulWidget {
  const KgSaleInputDialog({
    super.key,
    required this.product,
    this.existingItem,
  });

  final MockProduct product;
  final CartItem? existingItem;

  static Future<void> show(
    BuildContext context, {
    required MockProduct product,
    CartItem? existingItem,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => KgSaleInputDialog(
        product: product,
        existingItem: existingItem,
      ),
    );
  }

  @override
  ConsumerState<KgSaleInputDialog> createState() => _KgSaleInputDialogState();
}

class _KgSaleInputDialogState extends ConsumerState<KgSaleInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kgCtrl;
  late final TextEditingController _approxCtrl;

  static const _quickKgs = ['0.5', '1', '2', '5', '10'];

  @override
  void initState() {
    super.initState();
    final initialKg = widget.existingItem != null
        ? MockProduct.formatQty(widget.existingItem!.effectiveQuantity)
        : '';
    final initialApprox = widget.existingItem?.approximateQty != null &&
            widget.existingItem!.approximateQty! > 0
        ? widget.existingItem!.approximateQty.toString()
        : '';
    _kgCtrl = TextEditingController(text: initialKg);
    _approxCtrl = TextEditingController(text: initialApprox);
  }

  @override
  void dispose() {
    _kgCtrl.dispose();
    _approxCtrl.dispose();
    super.dispose();
  }

  void _submit(double availableKg) {
    if (!_formKey.currentState!.validate()) return;
    final soldKg = double.tryParse(_kgCtrl.text.trim()) ?? 0.0;
    if (soldKg <= 0) return;

    final rawApprox = _approxCtrl.text.trim();
    final approxQty = rawApprox.isEmpty ? 0 : (int.tryParse(rawApprox) ?? 0);

    ref.read(cartProvider.notifier).setKgItem(
          widget.product,
          kg: soldKg,
          approximateQty: approxQty > 0 ? approxQty : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final branchId = ref.watch(posFilterProvider).selectedBranchId;
    final inv = ref.watch(inventoryProvider);
    final availableKg = inv.getExactStock(branchId, widget.product.id);
    final availableApprox = inv.getApproxStock(branchId, widget.product.id);

    final parsedKg = double.tryParse(_kgCtrl.text.trim()) ?? 0.0;
    final discPct = widget.existingItem?.discountPct ?? 0.0;
    final estimatedTotal =
        parsedKg * widget.product.salePrice * (1 - discPct / 100);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Product Header ──────────────────────────────
                Row(
                  children: [
                    ProductAvatar(
                      imageEmoji: widget.product.imageEmoji,
                      customImagePath: widget.product.customImagePath,
                      size: 46,
                      fontSize: 24,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${fmt.format(widget.product.salePrice)} Ks / Kg'
                            '${widget.product.subcategory.isNotEmpty ? ' · ${widget.product.subcategory}' : ''}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Available stock summary banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'လက်ရှိ Stock: ${MockProduct.formatQty(availableKg)} Kg'
                          '${availableApprox > 0 ? ' (ခန့်မှန်း ~$availableApprox ခု)' : ''}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Kg selection chips
                Text(
                  'အမြန်ရွေးချယ်ရန် (Quick Kg)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _quickKgs.map((val) {
                    final numVal = double.parse(val);
                    final disabled = numVal > availableKg + 0.001;
                    final isSelected = _kgCtrl.text.trim() == val;
                    return ActionChip(
                      onPressed: disabled
                          ? null
                          : () {
                              setState(() {
                                _kgCtrl.text = val;
                                _kgCtrl.selection = TextSelection.collapsed(
                                    offset: _kgCtrl.text.length);
                              });
                            },
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                      label: Text(
                        '$val Kg',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? AppColors.textMuted
                              : (isSelected
                                  ? AppColors.textOnPrimary
                                  : AppColors.textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Field 1: Sold Kg
                Text(
                  'ဘယ်နှ Kg ရောင်းမှာလဲ (Sold Kg) *',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kgCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(availableKg),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ဥပမာ - 2.5',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 13),
                    suffixText: 'Kg',
                    suffixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    final val = double.tryParse(v?.trim() ?? '');
                    if (val == null || val <= 0) {
                      return 'ရောင်းမည့် Kg ပမာဏ ထည့်ပါ';
                    }
                    if (val > availableKg + 0.001) {
                      return 'လက်ကျန် (${MockProduct.formatQty(availableKg)} Kg) ထက် ကျော်လွန်နေပါသည်';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Field 2: Approximate Qty
                Text(
                  'ခန့်မှန်း အရေအတွက် (Approximate Qty)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _approxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _submit(availableKg),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: availableApprox > 0
                        ? 'ဥပမာ - 1 (Stock မှ ခန့်မှန်းအရေအတွက် နှုတ်မည်)'
                        : 'ဥပမာ - 1 (စိတ်ကြိုက်)',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                    suffixText: 'ခု',
                    suffixStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 0) {
                      return 'မှန်ကန်သော အရေအတွက် ထည့်ပါ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Calculated price preview
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ကျသင့်ငွေ (${MockProduct.formatQty(parsedKg)} Kg)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${fmt.format(estimatedTotal)} Ks',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('မလုပ်တော့ပါ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _submit(availableKg),
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 18),
                        label: Text(
                          widget.existingItem != null
                              ? 'ပြင်ဆင်သိမ်းဆည်းမည်'
                              : 'ခြင်းတောင်းထဲ ထည့်မည်',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
