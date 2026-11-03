import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../../data/mock/mock_products.dart';
import '../../domain/models/sale_transaction.dart';
import '../../ui/features/hr_payroll/models/payroll.dart';

/// Supported paper sizes for ESC/POS thermal printers
enum ReceiptPaperSize {
  mm58, // 58mm paper (~32 columns)
  mm80, // 80mm paper (~48 columns)
}

/// Printer connection settings
class PrinterSettings {
  const PrinterSettings({
    this.paperSize = ReceiptPaperSize.mm80,
    this.networkIp = '192.168.1.200',
    this.networkPort = 9100,
    this.autoCut = true,
    this.openCashDrawer = true,
  });

  final ReceiptPaperSize paperSize;
  final String networkIp;
  final int networkPort;
  final bool autoCut;
  final bool openCashDrawer;

  PrinterSettings copyWith({
    ReceiptPaperSize? paperSize,
    String? networkIp,
    int? networkPort,
    bool? autoCut,
    bool? openCashDrawer,
  }) {
    return PrinterSettings(
      paperSize: paperSize ?? this.paperSize,
      networkIp: networkIp ?? this.networkIp,
      networkPort: networkPort ?? this.networkPort,
      autoCut: autoCut ?? this.autoCut,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
    );
  }
}

/// Receipt printing service for 58mm and 80mm ESC/POS printers.
class ReceiptPrinterService {
  const ReceiptPrinterService();

  /// Sanitize text to standard ASCII/Latin1 range so ESC/POS generators do not fail
  static String _cleanAscii(String text, {String fallback = ''}) {
    final cleaned = text
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  /// Generate raw ESC/POS byte sequence for a sale transaction.
  Future<List<int>> generateReceiptBytes({
    required SaleTransaction transaction,
    required PrinterSettings settings,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperSize == ReceiptPaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final generator = Generator(paper, profile);

    List<int> bytes = [];

    // Reset printer & open drawer if configured
    bytes += generator.reset();
    if (settings.openCashDrawer) {
      bytes += generator.drawer();
    }

    final is58 = settings.paperSize == ReceiptPaperSize.mm58;
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    // ── 1. HEADER ─────────────────────────────────────────────
    bytes += generator.text(
      'Shwe Nanthar Myaing',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Nursery & Garden Center',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      _cleanAscii(transaction.branchName, fallback: 'Main Branch'),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Tel: +95 9 123 456 789 / +95 9 987 654 321',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr(ch: '=');

    // Meta details
    bytes += generator.row([
      PosColumn(
        text: 'Voucher: ${_cleanAscii(transaction.receiptNo)}',
        width: is58 ? 6 : 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: dateFmt.format(transaction.createdAt),
        width: is58 ? 6 : 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (transaction.cashierName.isNotEmpty) {
      bytes += generator.text('Cashier: ${_cleanAscii(transaction.cashierName, fallback: 'Cashier')}');
    }
    if (transaction.customerName != null &&
        transaction.customerName!.isNotEmpty) {
      bytes += generator.text('Customer: ${_cleanAscii(transaction.customerName!, fallback: 'Customer')}');
      if (transaction.customerPhone != null &&
          transaction.customerPhone!.isNotEmpty) {
        bytes += generator.text('Phone: ${_cleanAscii(transaction.customerPhone!)}');
      }
    }
    bytes += generator.hr(ch: '-');

    // ── 2. LINE ITEMS TABLE ──────────────────────────────────
    if (is58) {
      // 58mm: 32 columns compact layout
      bytes += generator.row([
        PosColumn(
            text: 'Item', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
            text: 'Qty',
            width: 2,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(
            text: 'Total',
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    } else {
      // 80mm: 48 columns detailed layout
      bytes += generator.row([
        PosColumn(
            text: 'Description',
            width: 6,
            styles: const PosStyles(bold: true)),
        PosColumn(
            text: 'Qty',
            width: 2,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(
            text: 'Price',
            width: 2,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(
            text: 'Total',
            width: 2,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }
    bytes += generator.hr(ch: '-');

    for (final item in transaction.items) {
      // Item name with origin tag if plant
      String displayName = _cleanAscii(item.productName, fallback: 'Product #${item.productId}');
      if (item.originType != null) {
        final originTag = switch (item.originType!) {
          OriginType.thaiImport => '[Thai]',
          OriginType.chinaImport => '[CN]',
          OriginType.local => '[Local]',
        };
        displayName = '$displayName $originTag';
      }

      final qtyStr = '${item.quantity}';
      final priceStr = currencyFmt.format(item.unitPrice);
      final totalStr = currencyFmt.format(item.lineTotal);

      if (is58) {
        bytes += generator.row([
          PosColumn(text: displayName, width: 6),
          PosColumn(
              text: qtyStr,
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
              text: totalStr,
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: displayName, width: 6),
          PosColumn(
              text: qtyStr,
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
              text: priceStr,
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
              text: totalStr,
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      // If item discount was applied, show separate discount sub-row
      if (item.discountPercent > 0) {
        bytes += generator.text(
          '  * Discount: ${item.discountPercent.toStringAsFixed(0)}% off',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
    }

    bytes += generator.hr(ch: '=');

    // ── 3. SUMMARY SECTION ───────────────────────────────────
    final subtotalStr = '${currencyFmt.format(transaction.subtotal)} Ks';
    final totalStr = '${currencyFmt.format(transaction.totalAmount)} Ks';

    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: is58 ? 6 : 8),
      PosColumn(
          text: subtotalStr,
          width: is58 ? 6 : 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (transaction.discountAmount > 0) {
      final discStr =
          '-${currencyFmt.format(transaction.discountAmount)} Ks';
      bytes += generator.row([
        PosColumn(text: 'Order Discount:', width: is58 ? 6 : 8),
        PosColumn(
            text: discStr,
            width: is58 ? 6 : 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    // Grand total in double height & bold
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL DUE:',
        width: is58 ? 6 : 7,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: totalStr,
        width: is58 ? 6 : 5,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '-');

    // ── 4. PAYMENT DETAILS ───────────────────────────────────
    bytes += generator.row([
      PosColumn(text: 'Payment Method:', width: is58 ? 6 : 7),
      PosColumn(
        text: _cleanAscii(transaction.paymentMethodLabel, fallback: 'Other'),
        width: is58 ? 6 : 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    if (transaction.isCash) {
      final tenderedStr =
          '${currencyFmt.format(transaction.tenderedAmount)} Ks';
      final changeStr =
          '${currencyFmt.format(transaction.changeAmount)} Ks';

      bytes += generator.row([
        PosColumn(text: 'Received:', width: is58 ? 6 : 7),
        PosColumn(
            text: tenderedStr,
            width: is58 ? 6 : 5,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Change:',
            width: is58 ? 6 : 7,
            styles: const PosStyles(bold: true)),
        PosColumn(
            text: changeStr,
            width: is58 ? 6 : 5,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    } else if (transaction.referenceId != null &&
        transaction.referenceId!.isNotEmpty) {
      bytes += generator.text('Txn / Ref: ${_cleanAscii(transaction.referenceId!)}');
    }

    if (transaction.notes != null && transaction.notes!.isNotEmpty) {
      bytes += generator.text('Note: ${_cleanAscii(transaction.notes!)}');
    }

    bytes += generator.hr(ch: '=');

    // ── 5. FOOTER ─────────────────────────────────────────────
    bytes += generator.text(
      'Thank you for shopping with us!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Plants sold are non-refundable.',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);

    // Barcode of Voucher ID
    try {
      bytes += generator.barcode(
        Barcode.code128(transaction.receiptNo.replaceAll('-', '').split('')),
      );
    } catch (_) {
      // Fallback if barcode generator doesn't match format
    }

    bytes += generator.feed(1);

    if (settings.autoCut) {
      bytes += generator.cut();
    }

    return bytes;
  }

  /// Generate raw ESC/POS byte sequence for an Employee Salary Payslip.
  Future<List<int>> generatePayslipBytes({
    required Payroll payroll,
    required String branchName,
    required PrinterSettings settings,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperSize == ReceiptPaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final generator = Generator(paper, profile);

    List<int> bytes = [];

    bytes += generator.reset();
    if (settings.openCashDrawer && payroll.paymentMethod == PayrollPaymentMethod.cash) {
      bytes += generator.drawer();
    }

    final is58 = settings.paperSize == ReceiptPaperSize.mm58;
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    // ── 1. HEADER ─────────────────────────────────────────────
    bytes += generator.text(
      'Shwe Nanthar Myaing',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      '*** SALARY PAYSLIP ***',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    bytes += generator.text(
      _cleanAscii(branchName, fallback: 'Main Branch'),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr(ch: '=');

    // ── 2. EMPLOYEE DETAILS ───────────────────────────────────
    bytes += generator.row([
      PosColumn(
        text: 'Slip ID: ${_cleanAscii(payroll.id)}',
        width: is58 ? 6 : 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'Period: ${payroll.payrollPeriod}',
        width: is58 ? 6 : 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.text(
      'Employee: ${_cleanAscii(payroll.employeeName)} (${_cleanAscii(payroll.employeeRole)})',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      'Date: ${dateFmt.format(payroll.paymentDate)}',
    );
    bytes += generator.hr(ch: '-');

    // ── 3. SALARY BREAKDOWN ───────────────────────────────────
    bytes += generator.row([
      PosColumn(
        text: 'Basic Salary:',
        width: is58 ? 6 : 8,
      ),
      PosColumn(
        text: '${currencyFmt.format(payroll.basicSalary)} Ks',
        width: is58 ? 6 : 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (payroll.bonusAmount > 0) {
      bytes += generator.row([
        PosColumn(
          text: '(+) Bonus: ${_cleanAscii(payroll.bonusDescription ?? "")}',
          width: is58 ? 7 : 8,
        ),
        PosColumn(
          text: '+${currencyFmt.format(payroll.bonusAmount)} Ks',
          width: is58 ? 5 : 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (payroll.deductionAmount > 0) {
      bytes += generator.row([
        PosColumn(
          text: '(-) Deduction: ${_cleanAscii(payroll.deductionDescription ?? "")}',
          width: is58 ? 7 : 8,
        ),
        PosColumn(
          text: '-${currencyFmt.format(payroll.deductionAmount)} Ks',
          width: is58 ? 5 : 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr(ch: '=');

    // ── 4. NET PAYABLE ────────────────────────────────────────
    bytes += generator.row([
      PosColumn(
        text: 'NET SALARY PAID:',
        width: is58 ? 6 : 7,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: '${currencyFmt.format(payroll.netSalary)} Ks',
        width: is58 ? 6 : 5,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '-');
    final methodStr = _cleanAscii(payroll.paymentMethod.label, fallback: payroll.paymentMethod.code.toUpperCase());
    bytes += generator.text('Payment Method: $methodStr');
    if (payroll.paidByName != null && payroll.paidByName!.isNotEmpty) {
      bytes += generator.text('Authorized By: ${_cleanAscii(payroll.paidByName!)}');
    }
    if (payroll.notes != null && payroll.notes!.isNotEmpty) {
      bytes += generator.text('Notes: ${_cleanAscii(payroll.notes!)}');
    }

    bytes += generator.feed(2);
    bytes += generator.text(
      '--------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Employee Signature',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    if (settings.autoCut) {
      bytes += generator.cut();
    }

    return bytes;
  }

  /// Send ESC/POS raw bytes to thermal printer over Network (LAN TCP Socket port 9100).
  Future<PrintResult> printOverNetwork({
    required List<int> bytes,
    required String host,
    int port = 9100,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return const PrintResult(
        success: true,
        message: 'Receipt printed successfully via Network',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Could not connect to printer at $host:$port ($e)',
      );
    }
  }
}

/// Print operation result
class PrintResult {
  const PrintResult({required this.success, required this.message});
  final bool success;
  final String message;
}
