import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/data/models/app_permission.dart';
import 'package:sitepyoe/data/repositories/branch_repository.dart';
import 'package:sitepyoe/domain/models/plant_origin.dart';
import 'package:sitepyoe/domain/models/product.dart' show Branch;
import 'package:sitepyoe/domain/models/sale_transaction.dart';
import 'package:sitepyoe/ui/features/inventory/view_models/inventory_notifier.dart';
import 'package:sitepyoe/ui/features/inventory/views/add_product_dialog.dart';
import 'package:sitepyoe/ui/features/inventory/views/inventory_screen.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';
import 'package:sitepyoe/ui/features/pos/view_models/transaction_notifier.dart';
import 'package:sitepyoe/ui/features/pos/widgets/cart_panel.dart';
import 'package:sitepyoe/ui/features/pos/widgets/category_filter_bar.dart';
import 'package:sitepyoe/ui/features/pos/widgets/product_grid_item.dart';
import 'package:sitepyoe/ui/features/pos/widgets/receipt_dialog.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/vendor_notifier.dart';
import 'package:sitepyoe/ui/features/purchases/views/purchase_screen.dart';
import 'package:sitepyoe/ui/features/settings/view_models/category_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/permission_group_notifier.dart';
import 'package:sitepyoe/ui/features/settings/view_models/plant_origin_notifier.dart';

class _StubCategoryNotifier extends CategoryNotifier {
  @override
  List<CategoryItem> build() => const [
        CategoryItem(
          id: 'cat-others',
          name: 'အထွေထွေ',
          englishName: 'Others',
          emoji: '📦',
          standardCategory: ProductCategory.others,
          subcategories: ['စပါးခွံ', 'မြေပဲခွံ'],
        ),
        CategoryItem(
          id: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
          name: 'Kg အရောင်း',
          englishName: 'Kg Sell',
          emoji: '📦',
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

class _StubTransactionNotifier extends TransactionNotifier {
  @override
  TransactionState build() => const TransactionState();
}

class _StubPermissionGroupNotifier extends PermissionGroupNotifier {
  @override
  List<PermissionGroup> build() => const [];
}

class _StubDefaultBranchNotifier extends DefaultBranchNotifier {
  @override
  String build() => 'branch_a';
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
      defaultBranchProvider.overrideWith(_StubDefaultBranchNotifier.new),
      catalogProvider.overrideWith(() => _StubCatalogNotifier(products)),
      catalogLoadingProvider.overrideWith((ref) => false),
      inventoryProvider.overrideWith(() => _StubInventoryNotifier(invState)),
      purchaseProvider.overrideWith(() => _StubPurchaseNotifier(purchaseState)),
      transactionProvider.overrideWith(_StubTransactionNotifier.new),
      permissionGroupProvider.overrideWith(_StubPermissionGroupNotifier.new),
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

    expect(find.text('Sale Price (ရောင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('Total Kg *'), findsNothing);

    await tester.tap(find.textContaining('Kg အရောင်း'));
    await tester.pumpAndSettle();

    expect(find.text('1 Kg Sale Price (1 Kg ရောင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('1 Kg Cost Price (1 Kg အရင်းဈေး MMK) *'), findsOneWidget);
    expect(find.text('Total Kg *'), findsWidgets);
    expect(find.text('Approx. Qty (ခန့်မှန်း ခု)'), findsWidgets);
  });

  testWidgets('CategoryFilterBar shows Kg အရောင်း subcategories (not Others)', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(),
        child: const MaterialApp(
          home: Scaffold(body: CategoryFilterBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Kg အရောင်း'));
    await tester.pumpAndSettle();

    expect(find.text('ဂျပန်ကြွေ'), findsOneWidget);
    expect(find.text('ဘွန်ဇိုင်း ဝါယာ'), findsOneWidget);
    expect(find.text('စပါးခွံ'), findsNothing);
  });

  testWidgets('POS tapping Kg ProductGridItem prompts Sold Kg + Approx Qty and updates CartPanel', (tester) async {
    tester.view.physicalSize = const Size(1440, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const kgProduct = MockProduct(
      id: 'prod-kg-pos',
      name: 'Test Pot',
      category: ProductCategory.others,
      categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
      categoryName: 'Kg Sell',
      subcategory: 'ဂျပန်ကြွေ',
      salePrice: 5000,
      costPrice: 3000,
      stock: 26,
      minStock: 2,
      unitOfMeasure: 'kg',
      approximateQuantity: 10,
      sku: 'KG-001',
    );

    final container = ProviderContainer(
      overrides: _baseOverrides(
        products: const [kgProduct],
        invState: const InventoryState(
          stocks: {'branch_a:prod-kg-pos': 26},
          exactStocks: {'branch_a:prod-kg-pos': 25.5},
          approxStocks: {'branch_a:prod-kg-pos': 10},
        ),
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 200,
                  height: 190,
                  child: ProductGridItem(product: kgProduct),
                ),
                Expanded(
                  child: CartPanel(
                    onHold: () {},
                    onCheckout: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25.5 Kg'), findsOneWidget);
    expect(find.text('5,000 Ks/Kg'), findsOneWidget);
    expect(find.text('~10 ခု'), findsOneWidget);

    await tester.tap(find.text('Test Pot'));
    await tester.pumpAndSettle();

    // Prompt dialog asks for Sold Kg and Approximate Qty
    expect(find.text('ဘယ်နှ Kg ရောင်းမှာလဲ (Sold Kg) *'), findsOneWidget);
    expect(find.text('ခန့်မှန်း အရေအတွက် (Approximate Qty)'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2.5');
    await tester.enterText(fields.at(1), '3');
    await tester.pumpAndSettle();

    expect(find.text('12,500 Ks'), findsWidgets);

    await tester.tap(find.text('ခြင်းတောင်းထဲ ထည့်မည်'));
    await tester.pumpAndSettle();

    final cart = container.read(cartProvider);
    expect(cart.items.length, 1);
    expect(cart.items.first.effectiveQuantity, 2.5);
    expect(cart.items.first.approximateQty, 3);
    expect(cart.totalAmount, 12500.0);

    expect(find.text('2.5 Kg · ~3 ခု'), findsOneWidget);
    expect(find.text('5,000 Ks / Kg'), findsOneWidget);
  });

  testWidgets('ReceiptDialog displays Kg weight and approximate count', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tx = SaleTransaction(
      receiptNo: 'SP-20261119-0001',
      branchId: 'branch_a',
      branchName: 'Branch A',
      items: const [
        SaleTransactionItem(
          productId: 'prod-kg-pos',
          productName: 'Test Pot',
          quantity: 3,
          exactQuantity: 2.5,
          approximateQty: 3,
          unitOfMeasure: 'kg',
          unitPrice: 5000,
          lineTotal: 12500,
        ),
      ],
      subtotal: 12500,
      totalAmount: 12500,
      paymentMethod: PaymentMethodType.cash,
      tenderedAmount: 12500,
      createdAt: DateTime(2026, 11, 19),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(),
        child: MaterialApp(
          home: Scaffold(body: ReceiptDialog(transaction: tx)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2.5 Kg'), findsOneWidget);
    expect(find.text('  ~Approx 3 pcs'), findsOneWidget);
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

    expect(find.textContaining('3,000 Ks/Kg'), findsOneWidget);
    expect(find.text('Stock: 10.5 Kg (~4 ခု)'), findsOneWidget);

    await tester.tap(find.text('ဂျပန်ကြွေ အိုးကြီး'));
    await tester.pumpAndSettle();

    expect(find.text('Total Kg'), findsOneWidget);
    expect(find.text('ခန့်မှန်း (Approx. Qty)'), findsOneWidget);
    expect(find.text('1 Kg ဝယ်ဈေး (Ks)'), findsOneWidget);

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

  testWidgets('InventoryScreen supports POS-style Category + Subcategory + Search filtering', (tester) async {
    tester.view.physicalSize = const Size(1440, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const pCeramic = MockProduct(
      id: 'inv-kg-1',
      name: 'ဂျပန်ကြွေ အိုးကြီး',
      category: ProductCategory.others,
      categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
      categoryName: 'Kg Sell',
      subcategory: 'ဂျပန်ကြွေ',
      salePrice: 5000,
      costPrice: 3000,
      stock: 20,
      unitOfMeasure: 'kg',
      approximateQuantity: 8,
    );
    const pWire = MockProduct(
      id: 'inv-kg-2',
      name: 'ဘွန်ဇိုင်း ဝါယာ 2mm',
      category: ProductCategory.others,
      categoryId: '1a510cb8-d3fa-44bd-bc32-43a6005d35cf',
      categoryName: 'Kg Sell',
      subcategory: 'ဘွန်ဇိုင်း ဝါယာ',
      salePrice: 8000,
      costPrice: 6000,
      stock: 5,
      unitOfMeasure: 'kg',
      approximateQuantity: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(
          products: const [pCeramic, pWire],
          invState: const InventoryState(
            stocks: {'branch_a:inv-kg-1': 20, 'branch_a:inv-kg-2': 5},
            exactStocks: {'branch_a:inv-kg-1': 20.5, 'branch_a:inv-kg-2': 5.0},
            approxStocks: {'branch_a:inv-kg-1': 8, 'branch_a:inv-kg-2': 3},
          ),
        ),
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially both items appear under All
    expect(find.text('ဂျပန်ကြွေ အိုးကြီး'), findsOneWidget);
    expect(find.text('ဘွန်ဇိုင်း ဝါယာ 2mm'), findsOneWidget);

    // Select "Kg အရောင်း" category tab -> subcategory chips appear
    await tester.tap(find.textContaining('Kg အရောင်း'));
    await tester.pumpAndSettle();

    expect(find.text('ဂျပန်ကြွေ'), findsOneWidget);
    expect(find.text('ဘွန်ဇိုင်း ဝါယာ'), findsOneWidget);

    // Select "ဂျပန်ကြွေ" subcategory chip -> only ceramic pot appears
    await tester.tap(find.text('ဂျပန်ကြွေ'));
    await tester.pumpAndSettle();

    expect(find.text('ဂျပန်ကြွေ အိုးကြီး'), findsOneWidget);
    expect(find.text('ဘွန်ဇိုင်း ဝါယာ 2mm'), findsNothing);
  });
}
