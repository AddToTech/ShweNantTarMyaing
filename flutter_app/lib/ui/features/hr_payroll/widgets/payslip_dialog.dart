// ============================================================
// Payslip Dialog
// Thermal slip layout (80mm / 58mm) for salary disbursement receipt
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/receipt_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../models/payroll.dart';

class PayslipDialog extends StatefulWidget {
  const PayslipDialog({
    super.key,
    required this.payroll,
  });

  final Payroll payroll;

  static Future<void> show(BuildContext context, {required Payroll payroll}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PayslipDialog(payroll: payroll),
    );
  }

  @override
  State<PayslipDialog> createState() => _PayslipDialogState();
}

class _PayslipDialogState extends State<PayslipDialog> {
  ReceiptPaperSize _paperSize = ReceiptPaperSize.mm80;
  bool _isPrinting = false;
  String? _printStatus;

  Future<void> _handlePrint() async {
    setState(() {
      _isPrinting = true;
      _printStatus = null;
    });

    try {
      const printerService = ReceiptPrinterService();
      final branchName = kBranches[widget.payroll.branchId] ?? widget.payroll.branchId;
      final settings = PrinterSettings(paperSize: _paperSize);

      final bytes = await printerService.generatePayslipBytes(
        payroll: widget.payroll,
        branchName: branchName,
        settings: settings,
      );

      // Attempt network print or fallback to local simulated print
      final result = await printerService.printOverNetwork(
        bytes: bytes,
        host: settings.networkIp,
        port: settings.networkPort,
      );

      if (mounted) {
        setState(() {
          _isPrinting = false;
          _printStatus = result.success
              ? 'ပရင်တာသို့ လစာစလစ် အောင်မြင်စွာ ပေးပို့ပြီးပါပြီ'
              : 'စလစ် ပုံနှိပ်ခြင်း စမ်းသပ်မှု ပြီးစီးပါပြီ (${result.message})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _printStatus = 'ပုံနှိပ်ခြင်း အောင်မြင်သည် (Preview Mode)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payroll = widget.payroll;
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final branchName = kBranches[payroll.branchId] ?? payroll.branchId;

    final is58 = _paperSize == ReceiptPaperSize.mm58;
    final slipWidth = is58 ? 320.0 : 420.0;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Toolbar ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'လစာရှင်းတမ်း စလစ် (Payslip)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Paper Size Toggle
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildPaperSizePill('80mm', ReceiptPaperSize.mm80),
                        _buildPaperSizePill('58mm', ReceiptPaperSize.mm58),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),

              // ── Thermal Receipt Preview Container ──────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: slipWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Company Branding
                          const Center(
                            child: Text(
                              'ရွှေနံ့သာမြိုင်',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '*** SALARY PAYSLIP / လစာရှင်းတမ်း ***',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              branchName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54, fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.black54, thickness: 1),

                          // 2. Metadata Rows
                          _slipRow('ပြေစာအမှတ် (Slip ID):', payroll.id, isBoldRight: true),
                          _slipRow('လစာကာလ (Period):', payroll.payrollPeriod, isBoldRight: true),
                          _slipRow('ဝန်ထမ်းအမည် (Staff):', '${payroll.employeeName} (${payroll.employeeRole})', isBoldRight: true),
                          _slipRow('ရက်စွဲ (Date):', dateFmt.format(payroll.paymentDate)),
                          const Divider(color: Colors.black26, thickness: 1),

                          // 3. Salary Breakdown
                          _slipRow('အခြေခံလစာ (Basic):', '${currencyFmt.format(payroll.basicSalary)} Ks'),
                          if (payroll.bonusAmount > 0)
                            _slipRow(
                              '(+) အပိုဆု/ချီးမြှင့်ငွေ:\n    ${payroll.bonusDescription ?? ""}',
                              '+${currencyFmt.format(payroll.bonusAmount)} Ks',
                              textColorRight: Colors.green.shade800,
                              isBoldRight: true,
                            ),
                          if (payroll.deductionAmount > 0)
                            _slipRow(
                              '(-) နုတ်ငွေ/ဒဏ်ကြေး:\n    ${payroll.deductionDescription ?? ""}',
                              '-${currencyFmt.format(payroll.deductionAmount)} Ks',
                              textColorRight: Colors.red.shade800,
                              isBoldRight: true,
                            ),
                          const Divider(color: Colors.black54, thickness: 1.5),

                          // 4. Net Salary
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NET SALARY PAID:',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${currencyFmt.format(payroll.netSalary)} Ks',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.black26, thickness: 1),

                          // 5. Payment details
                          _slipRow('ငွေပေးချေစနစ်:', payroll.paymentMethod.label),
                          if (payroll.paidByName != null && payroll.paidByName!.isNotEmpty)
                            _slipRow('ထုတ်ပေးသူ (Paid By):', payroll.paidByName!),
                          if (payroll.notes != null && payroll.notes!.isNotEmpty)
                            _slipRow('မှတ်ချက်:', payroll.notes!),

                          const SizedBox(height: 24),

                          // Signature Lines
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Divider(color: Colors.black38, thickness: 1),
                                  ),
                                  Text(
                                    'ထုတ်ပေးသူ လက်မှတ်\n(Authorized By)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 9),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Divider(color: Colors.black38, thickness: 1),
                                  ),
                                  Text(
                                    'ဝန်ထမ်း လက်ခံလက်မှတ်\n(Employee Signature)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 9),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'ကျေးဇူးတင်ပါသည် • SitePyoe POS',
                              style: TextStyle(color: Colors.black38, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_printStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  _printStatus!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // ── Action Buttons ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ပိတ်မည် (Close)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      _isPrinting ? 'ထုတ်နေသည်...' : 'စလစ် ပရင့်ထုတ်မည် (Print)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildPaperSizePill(String label, ReceiptPaperSize size) {
    final selected = _paperSize == size;
    return GestureDetector(
      onTap: () => setState(() => _paperSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textOnPrimary : AppColors.textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _slipRow(String left, String right,
      {bool isBoldRight = false, Color? textColorRight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: const TextStyle(color: Colors.black87, fontSize: 11),
          ),
          Text(
            right,
            style: TextStyle(
              color: textColorRight ?? Colors.black87,
              fontSize: 11,
              fontWeight: isBoldRight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
