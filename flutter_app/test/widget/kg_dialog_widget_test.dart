import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/data/repositories/branch_repository.dart';
import 'package:sitepyoe/domain/models/plant_origin.dart';
import 'package:sitepyoe/domain/models/product.dart' show Branch;
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/inventory/views/add_product_dialog.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/vendor_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/views/purchase_screen.dart';
import 'package:sitepyoe/ui/features/settings/view_models/category_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/plant_origin_notifier.dart';

class _StubCategoryNotifier extends CategoryNotifier {
  @override
  List<CategoryItem> build() => const [
        CategoryItem(
          id: 'cat-pots',
          name: 'ပန်းအိုးများ',
          englishName: 'Pots',
          emoji: '🪴',
          standardCategory: ProductCategory.pots,
          subcategories: ['စဉ့်အိုး'],
        ),
        CategoryItem(
          id: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
          name: 'Kg အရောင်း',
          englishName: 'Kg Sell',
          emoji: '📦',
          standardCategory: ProductCategory.others,
          subcategories: ['ဂျပန်ကြွေ', 'ဘွန်ဇိုင်း ဝါယာ'],
        ),
      ];
}

class _StubPlantOriginNotifier extends PlantOriginNotifier {
  @override
  List<PlantOrigin> build() => const [];
}

class _StubVendorNotifier extends VendorNotifier {
  @override
  List<Vendor> build() => const [];
}

class _StubBranchListNotifier extends BranchListNotifier {
  @override
  List<Branch> build() => const [];
}

class _StubBranchesNotifier extends BranchesNotifier {
  @override
  Map<String, String> build() => const {'branch_a': 'Branch A'};
}

class _StubCatalogNotifier extends CatalogNotifier {
  _StubCatalogNotifier(this._items);
  final List<MockProduct> _items;

  @override
  List<MockProduct> build() => _items;
}

class _StubInventoryNotifier extends InventoryNotifier {
  _StubInventoryNotifier(this._initial);
  final InventoryState _initial;

  @override
  InventoryState build() => _initial;
}

class _StubPurchaseNotifier extends PurchaseNotifier {
  _StubPurchaseNotifier(this._initial);
  final PurchaseState _initial;

  @override
  PurchaseState build() => _initial;
}

List<Override> _baseOverrides({
  List<MockProduct> products = const [],
  InventoryState invState = const InventoryState(),
  PurchaseState purchaseState = const PurchaseState(purchases: [], isLoading: false),
}) =>
    [
      categoryNotifierProvider.overrideWith(_StubCategoryNotifier.new),
      plantOriginProvider.overrideWith(_StubPlantOriginNotifier.new),
      vendorProvider.overrideWith(_StubVendorNotifier.new),
      branchListNotifierProvider.overrideWith(_StubBranchListNotifier.new),
      branchesProvider.overrideWith(_StubBranchesNotifier.new),
      catalogProvider.overrideWith(() => _StubCatalogNotifier(products)),
      catalogLoadingProvider.overrideWith((ref) => false),
      inventoryProvider.overrideWith(() => _StubInventoryNotifier(invState)),
      purchaseProvider.overrideWith(() => _StubPurchaseNotifier(purchaseState)),
    ];

void main() {
  testWidgets('AddProductDialog shows Total Kg and Approx. Qty when Kg အရောင်း is selected', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(),
        child: const MaterialApp(
          home: Scaffold(body: AddProductDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially non-Kg pricing labels appear
    expect(find.text('Sale Price (ရောင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('Total Kg *'), findsNothing);

    // Tap the "Kg အရောင်း" category chip
    await tester.tap(find.textContaining('Kg အရောင်း'));
    await tester.pumpAndSettle();

    // Kg pricing + Total Kg + Approx. Qty fields now appear
    expect(find.text('1 Kg Sale Price (1 Kg ရောင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('1 Kg Cost Price (1 Kg အရင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('Total Kg *'), findsWidgets);
    expect(find.text('Approx. Qty (ခန့်မှန်း ခု)'), findsWidgets);
  });

  testWidgets('PurchaseScreen shows Total Kg, Approx. Qty, and 1 Kg cost for Kg products', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const kgProduct = MockProduct(
      id: 'prod-kg-1',
      name: 'ဂျပန်ကြွေ အိုးကြီး',
      category: ProductCategory.others,
      categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
      categoryName: 'Kg Sell',
      subcategory: 'ဂျပန်ကြွေ',
      salePrice: 5000,
      costPrice: 3000,
      stock: 11,
      minStock: 2,
      unitOfMeasure: 'kg',
      approximateQuantity: 4,
      sku: 'KG-001',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(
          products: const [kgProduct],
          invState: const InventoryState(
            stocks: {'branch_a:prod-kg-1': 11},
            exactStocks: {'branch_a:prod-kg-1': 10.5},
            approxStocks: {'branch_a:prod-kg-1': 4},
          ),
        ),
        child: const MaterialApp(
          home: Scaffold(body: PurchaseScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Left picker renders Kg cost and stock with approx qty
    expect(find.textContaining('3,000 Ks/Kg'), findsOneWidget);
    expect(find.text('Stock: 10.5 Kg (~4 ခု)'), findsOneWidget);

    // Tap product to add to draft purchase items
    await tester.tap(find.text('ဂျပန်ကြွေ အိုးကြီး'));
    await tester.pumpAndSettle();

    // Draft row shows Kg badge, Total Kg, Approx. Qty, and 1 Kg Cost Price
    expect(find.text('Total Kg'), findsOneWidget);
    expect(find.text('ခန့်မှန်း (Approx. Qty)'), findsOneWidget);
    expect(find.text('1 Kg ဝယ်ဈေး (Ks)'), findsOneWidget);

    // Update Total Kg to 12.5 and verify calculated line cost 37,500 Ks
    final totalKgField = find.widgetWithText(TextField, 'Total Kg');
    await tester.enterText(totalKgField, '12.5');
    await tester.pumpAndSettle();

    expect(find.text('37,500 Ks'), findsWidgets);
  });

  testWidgets('PurchaseDetailDialog displays Kg quantity, approximate count, and Ks/Kg unit cost', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final kgPurchase = Purchase(
      id: 'pur-kg-1',
      purchaseNo: 'PO-KG-001',
      branchId: 'branch_a',
      vendorName: 'Test Vendor',
      purchaseDate: DateTime(2026, 11, 18),
      items: const [
        PurchaseItem(
          productId: 'p1',
          productName: 'ဂျပန်ကြွေ အိုးကြီး',
          quantity: 12.5,
          unitCost: 3000,
          approximateQty: 8,
          unitOfMeasure: 'kg',
        ),
      ],
      paidAmount: 37500,
      paymentStatus: PurchasePaymentStatus.paid,
      createdAt: DateTime(2026, 11, 18),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(
          purchaseState: PurchaseState(purchases: [kgPurchase], isLoading: false),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: PurchaseDetailDialog(
              purchaseId: kgPurchase.id,
              initialPurchase: kgPurchase,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12.5 Kg'), findsOneWidget);
    expect(find.text('ခန့်မှန်း ~8 ခု'), findsOneWidget);
    expect(find.text('3,000/Kg'), findsOneWidget);
    expect(find.text('37,500'), findsOneWidget);
  });
}
