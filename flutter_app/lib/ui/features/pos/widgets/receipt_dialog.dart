import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/receipt_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../view_models/transaction_notifier.dart';

/// Interactive dialog displaying the thermal receipt preview and ESC/POS printer controls.
class ReceiptDialog extends ConsumerStatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.transaction,
  });

  final SaleTransaction transaction;

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> {
  late ReceiptPaperSize _selectedPaper;
  late TextEditingController _ipCtrl;
  bool _isPrinting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(transactionProvider).printerSettings;
    _selectedPaper = settings.paperSize;
    _ipCtrl = TextEditingController(text: settings.networkIp);
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePrint() async {
    setState(() {
      _isPrinting = true;
      _statusMessage = 'Connecting to thermal printer at ${_ipCtrl.text}...';
      _isSuccess = false;
    });

    final currentSettings = ref.read(transactionProvider).printerSettings;
    final updatedSettings = currentSettings.copyWith(
      paperSize: _selectedPaper,
      networkIp: _ipCtrl.text.trim(),
    );

    ref.read(transactionProvider.notifier).updatePrinterSettings(updatedSettings);

    final result = await ref.read(transactionProvider.notifier).printReceipt(
          transaction: widget.transaction,
          overrideSettings: updatedSettings,
        );

    if (mounted) {
      setState(() {
        _isPrinting = false;
        _isSuccess = result.success;
        _statusMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final is58 = _selectedPaper == ReceiptPaperSize.mm58;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 860,
        height: 680,
        child: Row(
          children: [
            // ── Left: Thermal Receipt Preview ───────────────────────
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF1E2229),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Preview Header & Paper Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Thermal Receipt Preview',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 58mm / 80mm toggle
                        SegmentedButton<ReceiptPaperSize>(
                          segments: const [
                            ButtonSegment(
                              value: ReceiptPaperSize.mm58,
                              label: Text('58mm', style: TextStyle(fontSize: 11)),
                            ),
                            ButtonSegment(
                              value: ReceiptPaperSize.mm80,
                              label: Text('80mm', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                          selected: {_selectedPaper},
                          onSelectionChanged: (val) {
                            setState(() => _selectedPaper = val.first);
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.primary;
                              }
                              return AppColors.surfaceVariant;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return AppColors.textSecondary;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Paper Roll Simulation Card
                    Expanded(
                      child: Container(
                        width: is58 ? 290 : 380,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F6), // Thermal off-white paper
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF1A1A1A),
                              fontSize: 11,
                              height: 1.35,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Perforation top decor
                                const Center(
                                  child: Text('- - - - - - - - - - - - - - - - - - - -',
                                      style: TextStyle(color: Colors.black38)),
                                ),
                                const SizedBox(height: 6),

                                // Shop Name
                                const Text(
                                  'ရွှေနံ့သာမြိုင်',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const Text(
                                  'ဥယျာဉ်နှင့် အပင်အရောင်းစင်တာ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  widget.transaction.branchName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Tel: +95 9 123 456 789 / +95 9 987 654 321',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9.5),
                                ),
                                const Text('========================================',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Voucher & Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Voucher: ${widget.transaction.receiptNo}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(dateFmt.format(widget.transaction.createdAt)),
                                  ],
                                ),
                                Text('Cashier: ${widget.transaction.cashierName}'),
                                if (widget.transaction.customerName != null)
                                  Text('Customer: ${widget.transaction.customerName}'),
                                if (widget.transaction.customerPhone != null)
                                  Text('Phone: ${widget.transaction.customerPhone}'),
                                const Text('----------------------------------------',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Line Items Header
                                Row(
                                  children: [
                                    const Expanded(
                                        flex: 5,
                                        child: Text('ITEM',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    const Expanded(
                                        flex: 2,
                                        child: Text('QTY',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    if (!is58)
                                      const Expanded(
                                          flex: 3,
                                          child: Text('PRICE',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold))),
                                    const Expanded(
                                        flex: 3,
                                        child: Text('TOTAL',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const Text('----------------------------------------',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Line items
                                ...widget.transaction.items.map((item) {
                                  String displayName = item.productName;
                                  if (item.originType != null) {
                                    final tag = switch (item.originType!) {
                                      OriginType.thaiImport => '[Thai]',
                                      OriginType.chinaImport => '[CN]',
                                      OriginType.local => '[Local]',
                                    };
                                    displayName = '$displayName $tag';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 5,
                                                child: Text(displayName,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis)),
                                            Expanded(
                                                flex: 2,
                                                child: Text('${item.quantity}',
                                                    textAlign: TextAlign.center)),
                                            if (!is58)
                                              Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      currencyFmt
                                                          .format(item.unitPrice),
                                                      textAlign: TextAlign.right)),
                                            Expanded(
                                                flex: 3,
                                                child: Text(
                                                    currencyFmt
                                                        .format(item.lineTotal),
                                                    textAlign: TextAlign.right)),
                                          ],
                                        ),
                                        if (item.discountPercent > 0)
                                          Text(
                                            '  * ${item.discountPercent.toStringAsFixed(0)}% Off',
                                            style: const TextStyle(
                                                color: Colors.black54, fontSize: 9.5),
                                          ),
                                      ],
                                    ),
                                  );
                                }),

                                const Text('========================================',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Subtotal
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text(
                                        '${currencyFmt.format(widget.transaction.subtotal)} Ks'),
                                  ],
                                ),
                                if (widget.transaction.discountAmount > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Order Discount:'),
                                      Text(
                                          '-${currencyFmt.format(widget.transaction.discountAmount)} Ks'),
                                    ],
                                  ),

                                const SizedBox(height: 4),

                                // Total Due
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL DUE:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    Text(
                                      '${currencyFmt.format(widget.transaction.totalAmount)} Ks',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const Text('----------------------------------------',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Payment Info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Payment:'),
                                    Text(widget.transaction.paymentMethodLabel,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (widget.transaction.isCash) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Received (ပေးငွေ):'),
                                      Text(
                                          '${currencyFmt.format(widget.transaction.tenderedAmount)} Ks'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Change (ပြန်အမ်းငွေ):',
                                          style:
                                              TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '${currencyFmt.format(widget.transaction.changeAmount)} Ks',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ] else if (widget.transaction.referenceId != null) ...[
                                  Text(
                                      'Ref / Txn: ${widget.transaction.referenceId!}'),
                                ],

                                if (widget.transaction.notes != null)
                                  Text('Note: ${widget.transaction.notes!}'),

                                const SizedBox(height: 8),
                                const Text('========================================',
                                    maxLines: 1, overflow: TextOverflow.clip),

                                // Footer
                                const SizedBox(height: 4),
                                const Text(
                                  'Thank you for shopping with us!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'ကျေးဇူးတင်ပါသည်',
                                  textAlign: TextAlign.center,
                                ),
                                const Text(
                                  'Plants sold are non-refundable.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9),
                                ),
                                const SizedBox(height: 8),

                                // Barcode representation
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 32,
                                        width: 180,
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '||| | |||| || | || |||| | |||',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.transaction.receiptNo,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Center(
                                  child: Text('- - - - - - - - - - - - - - - - - - - -',
                                      style: TextStyle(color: Colors.black38)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Right: Printer Hardware & Action Panel ───────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.print_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Thermal Print Manager',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
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
                    const SizedBox(height: 18),

                    // Success banner if completed
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Order ${widget.transaction.receiptNo} Recorded Successfully!',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Printer Connection Details Card
                    Text(
                      'ESC/POS Printer Connection',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lan_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Network / LAN Thermal Printer',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Printer IP Address (Port 9100)',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ipCtrl,
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '192.168.1.200',
                              filled: true,
                              fillColor: AppColors.surface,
                              prefixIcon: Icon(Icons.router_rounded,
                                  color: AppColors.textMuted, size: 18),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Paper: ${_selectedPaper == ReceiptPaperSize.mm58 ? "58mm (32 cols)" : "80mm (48 cols)"}',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Message Display
                    if (_statusMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 16,
                              color: _isSuccess
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _isSuccess
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Action Buttons
                    ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _handlePrint,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print_rounded, size: 20),
                      label: Text(
                        _isPrinting ? 'Printing...' : 'Print Thermal Receipt',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done / Next Order',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
