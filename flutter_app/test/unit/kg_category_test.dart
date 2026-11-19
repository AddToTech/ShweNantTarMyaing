import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/domain/models/plant_origin.dart';
import 'package:sitepyoe/domain/models/sale_transaction.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';
import 'package:sitepyoe/ui/features/pos/view_models/pos_filter_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/vendor_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/category_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/plant_origin_notifier.dart';

class _TestInventoryNotifier extends InventoryNotifier {
  _TestInventoryNotifier(this._initial);
  final InventoryState _initial;

  @override
  InventoryState build() => _initial;
}

class _TestCategoryNotifier extends CategoryNotifier {
  _TestCategoryNotifier(this._cats);
  final List<CategoryItem> _cats;

  @override
  List<CategoryItem> build() => _cats;
}

class _TestCatalogNotifier extends CatalogNotifier {
  _TestCatalogNotifier(this._items);
  final List<MockProduct> _items;

  @override
  List<MockProduct> build() => _items;
}

class _TestVendorNotifier extends VendorNotifier {
  @override
  List<Vendor> build() => const [];
}

class _TestPlantOriginNotifier extends PlantOriginNotifier {
  @override
  List<PlantOrigin> build() => const [];
}

void main() {
  group('Kg အရောင်း Category, Product, Purchase & POS Sale Models', () {
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

    test('InventoryState & InventoryNotifier preserve and deduct fractional Kg + approximate qty', () {
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

      final afterAdd = container.read(inventoryProvider);
      expect(afterAdd.getExactStock('branch_a', 'p1'), 37.75);
      expect(afterAdd.getStock('branch_a', 'p1'), 38);
      expect(afterAdd.getApproxStock('branch_a', 'p1'), 15);

      // Deducting a Kg sale decrements both decimal Kg stock + approximate qty
      final deducted = container.read(inventoryProvider.notifier).deductStockExact(
            'branch_a',
            'p1',
            2.5,
            approximateQuantity: 3,
          );
      expect(deducted, isTrue);

      final afterSale = container.read(inventoryProvider);
      expect(afterSale.getExactStock('branch_a', 'p1'), 35.25);
      expect(afterSale.getStock('branch_a', 'p1'), 35);
      expect(afterSale.getApproxStock('branch_a', 'p1'), 12);

      // Exceeding exact stock is rejected
      final exceed = container.read(inventoryProvider.notifier).deductStockExact(
            'branch_a',
            'p1',
            50.0,
            approximateQuantity: 1,
          );
      expect(exceed, isFalse);
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
    });

    test('CartNotifier.setKgItem stores fractional Kg, approximateQty, and SaleTransactionItem preserves them', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const kgProduct = MockProduct(
        id: 'prod-kg-pos',
        name: 'Test',
        category: ProductCategory.others,
        categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
        categoryName: 'Kg Sell',
        salePrice: 5000,
        costPrice: 3000,
        stock: 25,
        unitOfMeasure: 'kg',
        approximateQuantity: 10,
      );

      container.read(cartProvider.notifier).setKgItem(
            kgProduct,
            kg: 2.5,
            approximateQty: 3,
          );

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      final item = cart.items.first;
      expect(item.isKgItem, isTrue);
      expect(item.effectiveQuantity, 2.5);
      expect(item.approximateQty, 3);
      expect(item.lineTotal, 12500.0);
      expect(cart.totalAmount, 12500.0);

      // Update weight to 0.5 Kg -> quantity stays >= 1 for count, exactQuantity is 0.5
      container.read(cartProvider.notifier).setKgItem(
            kgProduct,
            kg: 0.5,
            approximateQty: 1,
          );
      final updated = container.read(cartProvider);
      expect(updated.items.first.effectiveQuantity, 0.5);
      expect(updated.items.first.quantity, 1);
      expect(updated.items.first.lineTotal, 2500.0);

      const saleItem = SaleTransactionItem(
        productId: 'prod-kg-pos',
        productName: 'Test',
        quantity: 3,
        exactQuantity: 2.5,
        approximateQty: 3,
        unitOfMeasure: 'kg',
        unitPrice: 5000,
        lineTotal: 12500,
      );
      expect(saleItem.isKgItem, isTrue);
      expect(saleItem.displayQty, '2.5 Kg');
      expect(saleItem.approximateQty, 3);
    });

    test('filteredProductsProvider isolates Kg category products from Others category', () {
      const othersCat = CategoryItem(
        id: 'cat-others',
        name: 'အထွေထွေ',
        englishName: 'Others',
        emoji: '📦',
        standardCategory: ProductCategory.others,
        subcategories: ['စပါးခွံ', 'မြေဆွေး'],
      );
      const kgCat = CategoryItem(
        id: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
        name: 'Kg အရောင်း',
        englishName: 'Kg Sell',
        emoji: '📦',
        subcategories: ['ဂျပန်ကြွေ', 'ဘွန်ဇိုင်း ဝါယာ'],
      );
      const othersProd = MockProduct(
        id: 'p-other',
        name: 'စပါးခွံ ၁ အိတ်',
        category: ProductCategory.others,
        categoryId: 'cat-others',
        categoryName: 'Others',
        subcategory: 'စပါးခွံ',
        salePrice: 2000,
        costPrice: 1000,
        stock: 10,
      );
      const kgProd = MockProduct(
        id: 'p-kg',
        name: 'Test Pot',
        category: ProductCategory.others,
        categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
        categoryName: 'Kg Sell',
        subcategory: 'ဂျပန်ကြွေ',
        salePrice: 5000,
        costPrice: 3000,
        stock: 20,
        unitOfMeasure: 'kg',
      );

      final container = ProviderContainer(
        overrides: [
          categoryNotifierProvider.overrideWith(
            () => _TestCategoryNotifier(const [othersCat, kgCat]),
          ),
          catalogProvider.overrideWith(
            () => _TestCatalogNotifier(const [othersProd, kgProd]),
          ),
          inventoryProvider.overrideWith(
            () => _TestInventoryNotifier(
              const InventoryState(
                stocks: {'branch_a:p-other': 10, 'branch_a:p-kg': 20},
                exactStocks: {'branch_a:p-other': 10, 'branch_a:p-kg': 20.5},
              ),
            ),
          ),
          vendorProvider.overrideWith(_TestVendorNotifier.new),
          plantOriginProvider.overrideWith(_TestPlantOriginNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      container.read(posFilterProvider.notifier).selectCategoryItem(kgCat);
      final results = container.read(filteredProductsProvider);
      expect(results.length, 1);
      expect(results.first.id, 'p-kg');
    });

    test('MockProduct.matchesSubFilter filters subcategories and plant origins identically', () {
      const plantThai = MockProduct(
        id: 'plant-1',
        name: 'Mango Plant',
        category: ProductCategory.plants,
        subcategory: 'နှစ်ရှည်အသီးပင်',
        originType: OriginType.thaiImport,
        originName: 'ယိုးဒယား Import',
        salePrice: 10000,
        costPrice: 5000,
        stock: 5,
      );
      const kgCeramics = MockProduct(
        id: 'kg-1',
        name: 'Ceramic Pot',
        category: ProductCategory.others,
        categoryName: 'Kg Sell',
        subcategory: 'ဂျပန်ကြွေ',
        salePrice: 5000,
        costPrice: 3000,
        stock: 10,
        unitOfMeasure: 'kg',
      );

      expect(
        plantThai.matchesSubFilter(
          'ယိုးဒယား Import',
          isPlantsCategory: true,
          originNames: const ['ယိုးဒယား Import', 'ပြည်တွင်း'],
        ),
        isTrue,
      );
      expect(
        plantThai.matchesSubFilter(
          'ပြည်တွင်း',
          isPlantsCategory: true,
          originNames: const ['ယိုးဒယား Import', 'ပြည်တွင်း'],
        ),
        isFalse,
      );
      expect(
        plantThai.matchesSubFilter(
          'နှစ်ရှည်အသီးပင်',
          isPlantsCategory: true,
          originNames: const ['ယိုးဒယား Import', 'ပြည်တွင်း'],
        ),
        isTrue,
      );

      expect(kgCeramics.matchesSubFilter('ဂျပန်ကြွေ'), isTrue);
      expect(kgCeramics.matchesSubFilter('ဘွန်ဇိုင်း ဝါယာ'), isFalse);
      expect(kgCeramics.matchesSubFilter('All'), isTrue);
    });
  });
}
