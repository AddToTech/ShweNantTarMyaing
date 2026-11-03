import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/reports/view_models/sales_transactions_report_notifier.dart';
import 'package:sitepyoe/ui/features/reports/view_models/product_sales_report_notifier.dart';
import 'package:sitepyoe/ui/features/reports/view_models/stock_valuation_report_notifier.dart';
import 'package:sitepyoe/ui/features/reports/view_models/credit_ledger_notifier.dart';

void main() {
  group('Expanded Reports System Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Sales Transactions Report computes cash, digital, credit and net totals', () {
      final notifier = container.read(salesReportFilterProvider.notifier);
      // Set to all time to evaluate complete baseline
      notifier.setDateFilter(SalesReportDateFilter.allTime);

      final report = container.read(salesTransactionsReportProvider);

      expect(report.transactions, isNotEmpty);
      expect(report.totalNetSales, greaterThan(0));
      expect(report.totalCash, greaterThan(0));
      expect(report.totalDigital, greaterThan(0));
      expect(report.totalCredit, greaterThan(0));
      expect(
        report.totalNetSales,
        closeTo(report.totalCash + report.totalDigital + report.totalCredit, 0.01),
      );
    });

    test('Sales Transactions Report filters by branch and payment method', () {
      final notifier = container.read(salesReportFilterProvider.notifier);
      notifier.setDateFilter(SalesReportDateFilter.allTime);
      notifier.setBranch('branch_a');
      notifier.setPaymentMethod('cash');

      final report = container.read(salesTransactionsReportProvider);
      for (final t in report.transactions) {
        expect(t.branchId, 'branch_a');
        expect(t.isCash, isTrue);
      }
    });

    test('Product-wise Sales Analysis computes revenue, cost and margins per SKU', () {
      final filterNotifier = container.read(productSalesReportFilterProvider.notifier);
      filterNotifier.setSortBy(ProductSalesSortBy.highestRevenue);

      final items = container.read(productWiseSalesDataProvider);
      expect(items, isNotEmpty);

      // Verify sorted by revenue descending
      for (int i = 0; i < items.length - 1; i++) {
        expect(items[i].revenueTotal, greaterThanOrEqualTo(items[i + 1].revenueTotal));
      }

      // Check margin calculation on top item
      final topItem = items.first;
      expect(topItem.grossProfit, closeTo(topItem.revenueTotal - topItem.costTotal, 0.01));
    });

    test('Product-wise Sales Analysis filters by category and origin', () {
      final filterNotifier = container.read(productSalesReportFilterProvider.notifier);
      filterNotifier.setCategory(ProductCategory.plants);
      filterNotifier.setOrigin('thaiImport');

      final items = container.read(productWiseSalesDataProvider);
      for (final item in items) {
        expect(item.category, ProductCategory.plants);
        expect(item.originType, OriginType.thaiImport);
      }
    });

    test('Stock Valuation Report aggregates total SKUs, physical stock and asset values', () {
      final summary = container.read(stockValuationReportProvider);

      expect(summary.totalSkus, greaterThan(0));
      expect(summary.totalUnits, greaterThan(0));
      expect(summary.totalCostValue, greaterThan(0));
      expect(summary.potentialRetailValue, greaterThan(summary.totalCostValue));

      for (final item in summary.items) {
        expect(item.totalStock, item.branchAStock + item.branchBStock);
        expect(item.totalCostValue, closeTo(item.totalStock * item.unitCost, 0.01));
      }
    });

    test('Credit / Debt Ledger tracks outstanding balances and marks debt as cleared', () {
      final ledger = container.read(creditLedgerProvider);

      expect(ledger.entries, isNotEmpty);
      expect(ledger.totalDebtIncurred, greaterThan(0));
      expect(ledger.totalOutstandingDebt, greaterThan(0));

      final firstUnpaid = ledger.entries.firstWhere((e) => !e.isPaid);
      final initialOutstanding = firstUnpaid.balanceOutstanding;
      expect(initialOutstanding, greaterThan(0));

      // Mark as paid
      container.read(creditLedgerProvider.notifier).markAsPaid(firstUnpaid.id);

      final updatedLedger = container.read(creditLedgerProvider);
      final updatedEntry = updatedLedger.entries.firstWhere((e) => e.id == firstUnpaid.id);

      expect(updatedEntry.isPaid, isTrue);
      expect(updatedEntry.balanceOutstanding, 0.0);
      expect(updatedEntry.paidAmount, updatedEntry.totalDebt);
    });

    test('Credit / Debt Ledger partial payment reduces outstanding balance correctly', () {
      final ledger = container.read(creditLedgerProvider);
      final unpaid = ledger.entries.firstWhere((e) => e.id == 'crd-101'); // Daw Mya (32,000 Ks)
      expect(unpaid.balanceOutstanding, 32000);

      container.read(creditLedgerProvider.notifier).recordPayment('crd-101', 12000);

      final updatedLedger = container.read(creditLedgerProvider);
      final updatedEntry = updatedLedger.entries.firstWhere((e) => e.id == 'crd-101');

      expect(updatedEntry.paidAmount, 12000);
      expect(updatedEntry.balanceOutstanding, 20000);
      expect(updatedEntry.isPaid, isFalse);
    });
  });
}
