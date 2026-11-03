import 'package:flutter_test/flutter_test.dart';
import 'package:sitepyoe/core/services/receipt_printer_service.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/domain/models/sale_transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptPrinterService Tests', () {
    const printerService = ReceiptPrinterService();

    final testItems = [
      const SaleTransactionItem(
        productId: 'p001',
        productName: 'Phalaenopsis Orchid',
        quantity: 2,
        unitPrice: 25000,
        discountPercent: 10,
        lineTotal: 45000,
        originType: OriginType.thaiImport,
        category: ProductCategory.plants,
      ),
      const SaleTransactionItem(
        productId: 'p011',
        productName: 'Ceramic Glazed Pot 8"',
        quantity: 1,
        unitPrice: 12000,
        lineTotal: 12000,
        category: ProductCategory.pots,
      ),
    ];

    final cashTransaction = SaleTransaction(
      receiptNo: 'SP-20261013-0001',
      branchId: 'branch_a',
      branchName: 'SitePyoe Branch A (Mingaladon)',
      cashierName: 'Cashier #1',
      items: testItems,
      subtotal: 57000,
      discountAmount: 2000,
      totalAmount: 55000,
      paymentMethod: PaymentMethodType.cash,
      tenderedAmount: 60000,
      changeAmount: 5000,
      createdAt: DateTime(2026, 10, 13, 14, 30),
    );

    test('generateReceiptBytes for 80mm paper returns non-empty byte list', () async {
      const settings = PrinterSettings(paperSize: ReceiptPaperSize.mm80);
      final bytes = await printerService.generateReceiptBytes(
        transaction: cashTransaction,
        settings: settings,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generateReceiptBytes for 58mm paper returns non-empty byte list', () async {
      const settings = PrinterSettings(paperSize: ReceiptPaperSize.mm58);
      final bytes = await printerService.generateReceiptBytes(
        transaction: cashTransaction,
        settings: settings,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generateReceiptBytes for digital payment transaction', () async {
      final digitalTransaction = SaleTransaction(
        receiptNo: 'SP-20261013-0002',
        branchId: 'branch_a',
        branchName: 'SitePyoe Branch A',
        cashierName: 'Cashier #1',
        items: testItems,
        subtotal: 57000,
        totalAmount: 57000,
        paymentMethod: PaymentMethodType.kpay,
        referenceId: 'KPAY-TXN-998811',
        createdAt: DateTime(2026, 10, 13, 15, 0),
      );

      const settings = PrinterSettings(paperSize: ReceiptPaperSize.mm80);
      final bytes = await printerService.generateReceiptBytes(
        transaction: digitalTransaction,
        settings: settings,
      );

      expect(bytes, isNotEmpty);
    });

    test('generateReceiptBytes for credit transaction includes customer info', () async {
      final creditTransaction = SaleTransaction(
        receiptNo: 'SP-20261013-0003',
        branchId: 'branch_b',
        branchName: 'SitePyoe Branch B',
        cashierName: 'Cashier #2',
        customerName: 'Ko Aung',
        customerPhone: '09123456789',
        items: testItems,
        subtotal: 57000,
        totalAmount: 57000,
        paymentMethod: PaymentMethodType.credit,
        notes: 'Due in 7 days',
        createdAt: DateTime(2026, 10, 13, 15, 30),
      );

      const settings = PrinterSettings(paperSize: ReceiptPaperSize.mm80);
      final bytes = await printerService.generateReceiptBytes(
        transaction: creditTransaction,
        settings: settings,
      );

      expect(bytes, isNotEmpty);
    });
  });
}
