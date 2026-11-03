import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/reports/view_models/reports_notifier.dart';

void main() {
  group('ReportsNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Reports dashboard computes sales summary with gross profit and margin', () {
      final data = container.read(reportsDataProvider);

      expect(data.salesSummary.grossRevenue, greaterThan(0));
      expect(data.salesSummary.totalCost, greaterThan(0));
      expect(data.salesSummary.grossProfit, greaterThan(0));
      expect(data.salesSummary.grossMargin, inInclusiveRange(10.0, 90.0));
      expect(data.salesSummary.orderCount, greaterThan(0));
      expect(data.salesSummary.unitsCount, greaterThan(0));
    });

    test('Category summaries are generated and ranked by revenue', () {
      final data = container.read(reportsDataProvider);
      final categories = data.categorySummaries;

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.category == ProductCategory.plants), isTrue);
      expect(categories.any((c) => c.category == ProductCategory.pots), isTrue);

      // Verify descending sort order by revenue
      for (int i = 0; i < categories.length - 1; i++) {
        expect(categories[i].revenue, greaterThanOrEqualTo(categories[i + 1].revenue));
      }
    });

    test('Wastage loss and payroll OPEX calculate total financial loss and net profit impact', () {
      final data = container.read(reportsDataProvider);

      expect(data.wastageSummary.totalLoss, greaterThan(0));
      expect(data.wastageSummary.totalQuantity, greaterThan(0));
      expect(data.operatingExpense, greaterThan(0));

      // Net profit = gross profit - wastage loss - operating expenses (salaries)
      final expectedNet = data.salesSummary.grossProfit - data.wastageSummary.totalLoss - data.operatingExpense;
      expect(data.netProfit, expectedNet);
    });

    test('Changing report period filters data properly', () {
      final notifier = container.read(reportsFilterProvider.notifier);

      notifier.setPeriod(ReportPeriod.today);
      final todayData = container.read(reportsDataProvider);
      expect(todayData.filter.period, ReportPeriod.today);

      notifier.setPeriod(ReportPeriod.allTime);
      final allTimeData = container.read(reportsDataProvider);
      expect(allTimeData.filter.period, ReportPeriod.allTime);
      expect(allTimeData.salesSummary.grossRevenue, greaterThanOrEqualTo(todayData.salesSummary.grossRevenue));
    });
  });
}
