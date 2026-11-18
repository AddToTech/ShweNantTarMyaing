import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/category_notifier.dart';

class _TestInventoryNotifier extends InventoryNotifier {
  _TestInventoryNotifier(this._initial);
  final InventoryState _initial;

  @override
  InventoryState build() => _initial;
}

void main() {
  group('Kg အရောင်း Category, Product & Purchase Models', () {
    test('CategoryItem.isKgCategory identifies Kg Sell / Kg အရောင်း', () {
      const kgCat = CategoryItem(
        id: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
        name: 'Kg အရောင်း',
        englishName: 'Kg Sell',
        emoji: '📦',
        subcategories: ['ဂျပန်ကြွေ', 'ဘွန်ဇိုင်း ဝါယာ'],
      );
      const potsCat = CategoryItem(
        id: 'cat-pots',
        name: 'ပန်းအိုးများ',
        englishName: 'Pots',
        emoji: '🪴',
        standardCategory: ProductCategory.pots,
        subcategories: ['စဉ့်အိုး'],
      );

      expect(kgCat.isKgCategory, isTrue);
      expect(potsCat.isKgCategory, isFalse);
    });

    test('MockProduct parses Kg unit, approximate_quantity, and formats decimals cleanly', () {
      expect(MockProduct.formatQty(25.5), '25.5');
      expect(MockProduct.formatQty(25.0), '25');
      expect(MockProduct.formatQty(10.25), '10.25');
      expect(MockProduct.formatQty(0), '0');

      final parsed = MockProduct.fromJson({
        'id': 'prod-kg-1',
        'name': 'ဂျပန်ကြွေ အိုးကြီး',
        'category_id': '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
        'category_name': 'Kg Sell',
        'subcategory_name': 'ဂျပန်ကြွေ',
        'sale_price': 5000,
        'cost_price': 3000,
        'stock_quantity': 26,
        'min_alert_threshold': 5,
        'unit_of_measure': 'kg',
        'approximate_quantity': 12,
        'sku': 'KG-001',
      });

      expect(parsed.unitOfMeasure, 'kg');
      expect(parsed.approximateQuantity, 12);
      expect(parsed.isKgProduct, isTrue);

      const normal = MockProduct(
        id: 'prod-pc-1',
        name: 'ပန်းအိုး',
        category: ProductCategory.pots,
        salePrice: 15000,
        costPrice: 10000,
        stock: 5,
      );
      expect(normal.unitOfMeasure, 'piece');
      expect(normal.approximateQuantity, isNull);
      expect(normal.isKgProduct, isFalse);
    });

    test('InventoryState & ProductWithStock preserve exact decimal Kg & approximate quantity', () {
      final container = ProviderContainer(
        overrides: [
          inventoryProvider.overrideWith(
            () => _TestInventoryNotifier(
              const InventoryState(
                stocks: {'branch_a:p1': 26},
                exactStocks: {'branch_a:p1': 25.5},
                approxStocks: {'branch_a:p1': 10},
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final invState = container.read(inventoryProvider);
      expect(invState.getStock('branch_a', 'p1'), 26);
      expect(invState.getExactStock('branch_a', 'p1'), 25.5);
      expect(invState.getApproxStock('branch_a', 'p1'), 10);

      // Adding a Kg purchase increments decimal stock + approximate qty
      container.read(inventoryProvider.notifier).addStockExact(
            'branch_a',
            'p1',
            12.25,
            approximateQuantity: 5,
          );

      final updated = container.read(inventoryProvider);
      expect(updated.getExactStock('branch_a', 'p1'), 37.75);
      expect(updated.getStock('branch_a', 'p1'), 38);
      expect(updated.getApproxStock('branch_a', 'p1'), 15);

      const kgProduct = MockProduct(
        id: 'p1',
        name: 'ဂျပန်ကြွေ',
        category: ProductCategory.others,
        salePrice: 5000,
        costPrice: 3000,
        stock: 0,
        minStock: 0,
        unitOfMeasure: 'kg',
        approximateQuantity: 1,
      );
      const subOneKg = ProductWithStock(
        product: kgProduct,
        stock: 0,
        exactStock: 0.5,
        approximateQty: 1,
        branchId: 'branch_a',
      );
      expect(subOneKg.displayStock, 0.5);
      expect(subOneKg.isOutOfStock, isFalse);
      expect(subOneKg.isLowStock, isFalse);
    });

    test('PurchaseItem computes Total Kg x 1 Kg Cost Price and exposes isKgItem', () {
      const kgItem = PurchaseItem(
        productId: 'p1',
        productName: 'ဂျပန်ကြွေ',
        quantity: 20.5,
        unitCost: 3000,
        approximateQty: 12,
        unitOfMeasure: 'kg',
      );

      expect(kgItem.isKgItem, isTrue);
      expect(kgItem.totalCost, 61500.0);
      expect(kgItem.approximateQty, 12);

      final modified = kgItem.copyWith(quantity: 10.0, approximateQty: 6);
      expect(modified.totalCost, 30000.0);
      expect(modified.approximateQty, 6);
      expect(modified.isKgItem, isTrue);
    });
  });
}
