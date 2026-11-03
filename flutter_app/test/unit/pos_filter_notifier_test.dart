import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/pos/view_models/pos_filter_notifier.dart';

void main() {
  group('PosFilterNotifier and filteredProductsProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial filter shows all products', () {
      final filter = container.read(posFilterProvider);
      expect(filter.selectedCategory, ProductCategory.all);
      expect(filter.selectedSubFilter, 'All');
      expect(filter.searchQuery, isEmpty);
      expect(filter.selectedBranchId, 'branch_a');

      final products = container.read(filteredProductsProvider);
      expect(products.length, kMockProducts.length);
    });

    test('Filter by category returns only products of that category', () {
      container.read(posFilterProvider.notifier).selectCategory(ProductCategory.plants);

      final products = container.read(filteredProductsProvider);
      expect(products, isNotEmpty);
      expect(products.every((p) => p.category == ProductCategory.plants), isTrue);
    });

    test('Filter plants by origin (Thai Import)', () {
      final notifier = container.read(posFilterProvider.notifier);
      notifier.selectCategory(ProductCategory.plants);
      notifier.selectSubFilter('Thai Import');

      final products = container.read(filteredProductsProvider);
      expect(products, isNotEmpty);
      expect(products.every((p) => p.originType == OriginType.thaiImport), isTrue);
    });

    test('Filter pots by subcategory (ကြွေအိုး)', () {
      final notifier = container.read(posFilterProvider.notifier);
      notifier.selectCategory(ProductCategory.pots);
      notifier.selectSubFilter('ကြွေအိုး');

      final products = container.read(filteredProductsProvider);
      expect(products, isNotEmpty);
      expect(products.every((p) => p.subcategory == 'ကြွေအိုး'), isTrue);
    });

    test('Filter by search query (name)', () {
      final notifier = container.read(posFilterProvider.notifier);
      notifier.updateSearch('သစ်ခွ');

      final products = container.read(filteredProductsProvider);
      expect(products.length, greaterThanOrEqualTo(1));
      expect(products.first.name, contains('သစ်ခွ'));
    });

    test('Switching category resets subFilter to All', () {
      final notifier = container.read(posFilterProvider.notifier);
      notifier.selectCategory(ProductCategory.plants);
      notifier.selectSubFilter('Thai Import');
      expect(container.read(posFilterProvider).selectedSubFilter, 'Thai Import');

      notifier.selectCategory(ProductCategory.pots);
      expect(container.read(posFilterProvider).selectedSubFilter, 'All');
    });

    test('Changing branch updates branch selection', () {
      final notifier = container.read(posFilterProvider.notifier);
      notifier.selectBranch('branch_b');
      expect(container.read(posFilterProvider).selectedBranchId, 'branch_b');
    });
  });
}
