import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../view_models/cart_notifier.dart';
import '../view_models/pos_filter_notifier.dart';
import '../view_models/transaction_notifier.dart';
import 'receipt_dialog.dart';

/// Payment Modal Dialog for SitePyoe Tablet POS
class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  PaymentMethodType _selectedMethod = PaymentMethodType.cash;

  // Cash controllers
  final _receivedCtrl = TextEditingController();

  // Digital controllers
  String _digitalProvider = 'KPay';
  final _refCtrl = TextEditingController();

  // Credit controllers
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _creditNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default tender is exact total
    final total = ref.read(cartProvider).totalAmount;
    _receivedCtrl.text = NumberFormat('#,###').format(total);
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _refCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _creditNotesCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(String text) {
    final clean = text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _setCashAmount(double amount) {
    setState(() {
      _receivedCtrl.text = NumberFormat('#,###').format(amount);
    });
  }

  Future<void> _onConfirmPayment() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final branchId = ref.read(posFilterProvider).selectedBranchId;
    final total = cart.totalAmount;

    double tendered = 0.0;
    double change = 0.0;
    String? refId;
    String? custName;
    String? custPhone;
    String? notes;

    if (_selectedMethod == PaymentMethodType.cash) {
      tendered = _parseAmount(_receivedCtrl.text);
      if (tendered < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ကျသင့်ငွေထက် လက်ခံငွေ နည်းနေပါသည်! (Received amount is less than total due)'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      change = (tendered - total).clamp(0.0, double.infinity);
    } else if (_selectedMethod == PaymentMethodType.credit) {
      custName = _customerNameCtrl.text.trim();
      custPhone = _customerPhoneCtrl.text.trim();
      notes = _creditNotesCtrl.text.trim();

      if (custName.isEmpty || custPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('အကြွေးစနစ်အတွက် ဝယ်သူအမည်နှင့် ဖုန်းနံပါတ် ဖြည့်ရန် လိုအပ်ပါသည်!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      refId = _refCtrl.text.trim();
      notes = 'Provider: $_digitalProvider';
    }

    // Record transaction on backend
    final transaction = await ref.read(transactionProvider.notifier).completeSale(
          cart: cart,
          branchId: branchId,
          paymentMethod: _selectedMethod,
          tenderedAmount: tendered,
          changeAmount: change,
          referenceId: refId,
          customerName: custName,
          customerPhone: custPhone,
          notes: notes,
        );

    if (transaction == null || !mounted) return;

    // Clear active cart & advance ticket number
    ref.read(cartProvider.notifier).advanceTicket();

    // Close Payment Modal
    Navigator.of(context).pop();

    // Open Thermal Receipt Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceiptDialog(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currencyFmt = NumberFormat('#,###');
    final total = cart.totalAmount;
    final tendered = _parseAmount(_receivedCtrl.text);
    final change = tendered - total;

    // Quick cash denominations
    final quickCashList = <double>[
      total, // Exact amount
      10000,
      20000,
      50000,
      100000,
    ];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.point_of_sale_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'ငွေရှင်းလွှာ (Payment Checkout)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Total Due Banner ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.navRailBg,
                      AppColors.navRailBg.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ကျသင့်ငွေ စုစုပေါင်း (TOTAL DUE)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ပစ္စည်း ${cart.itemCount} မျိုး · ${cart.ticketNumber}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${currencyFmt.format(total)} Ks',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Payment Methods Selector ────────────────────────
              Text(
                'Payment Method',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _methodTab(
                    method: PaymentMethodType.cash,
                    icon: Icons.payments_rounded,
                    label: 'Cash (ငွေသား)',
                  ),
                  const SizedBox(width: 10),
                  _methodTab(
                    method: PaymentMethodType.kpay,
                    icon: Icons.phone_android_rounded,
                    label: 'KPay / Wave',
                  ),
                  const SizedBox(width: 10),
                  _methodTab(
                    method: PaymentMethodType.credit,
                    icon: Icons.receipt_long_rounded,
                    label: 'Credit (အကြွေး)',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Method Specific Form ─────────────────────────────
              if (_selectedMethod == PaymentMethodType.cash) ...[
                // Quick cash buttons
                Text(
                  'Quick Cash (အမြန်ရွေးချယ်ရန်)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickCashList.map((amt) {
                    final isExact = amt == total;
                    final isCurrent = tendered == amt;
                    final label = isExact
                        ? 'အတိအကျ (${currencyFmt.format(amt)})'
                        : '${currencyFmt.format(amt)} Ks';

                    return ActionChip(
                      onPressed: () => _setCashAmount(amt),
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : (isExact
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceVariant),
                      side: BorderSide(
                        color: isCurrent
                            ? AppColors.primary
                            : (isExact
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.border),
                      ),
                      label: Text(
                        label,
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : (isExact
                                  ? AppColors.primary
                                  : AppColors.textPrimary),
                          fontSize: 11,
                          fontWeight:
                              isExact ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Received amount input
                Text(
                  'လက်ခံရရှိငွေ (Received Amount)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _receivedCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'လက်ခံရရှိငွေ ရိုက်ထည့်ပါ',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    suffixText: 'Ks',
                    suffixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.attach_money_rounded,
                        color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Change Calculation Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: change >= 0
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: change >= 0
                          ? AppColors.success.withValues(alpha: 0.35)
                          : AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              change >= 0
                                  ? Icons.currency_exchange_rounded
                                  : Icons.warning_amber_rounded,
                              color: change >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                change >= 0
                                    ? 'Change Due (ပြန်အမ်းငွေ):'
                                    : 'Remaining Balance (ကျန်ငွေ):',
                                style: TextStyle(
                                  color: change >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currencyFmt.format(change.abs())} Ks',
                        style: TextStyle(
                          color: change >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedMethod == PaymentMethodType.kpay) ...[
                // Digital Sub-provider selector
                Row(
                  children: ['KPay', 'WavePay', 'Mobile Banking'].map((prov) {
                    final isSel = _digitalProvider == prov;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(prov),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _digitalProvider = prov);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Text(
                  'Transaction / Reference ID',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _refCtrl,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g., 2026101300923841',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    prefixIcon: Icon(Icons.qr_code_rounded,
                        color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ] else ...[
                // Credit (အကြွေး) form
                Text(
                  'Customer Name (ဝယ်ယူသူအမည်) *',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _customerNameCtrl,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g., U Kyaw Win',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    prefixIcon: Icon(Icons.person_rounded,
                        color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Customer Phone (ဖုန်းနံပါတ်) *',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '09xxxxxxxxx',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    prefixIcon: Icon(Icons.phone_rounded,
                        color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'ငွေချေမှု မှတ်ချက် / သတ်မှတ်ချက်',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _creditNotesCtrl,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ဥပမာ - ၇ ရက်အတွင်း ပေးချေမည်',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('မလုပ်တော့ပါ (Cancel)'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _onConfirmPayment,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'ငွေရှင်းပြီး ဘောက်ချာထုတ်မည်',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodTab({
    required PaymentMethodType method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
