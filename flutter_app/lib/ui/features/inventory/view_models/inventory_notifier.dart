import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/mock/mock_products.dart';

/// Stock record for a specific product at a specific branch
class BranchStock {
  const BranchStock({
    required this.branchId,
    required this.productId,
    required this.quantity,
    required this.minStock,
  });

  final String branchId;
  final String productId;
  final int quantity;
  final int minStock;

  bool get isLowStock => quantity <= minStock;
  bool get isOutOfStock => quantity <= 0;

  BranchStock copyWith({int? quantity, int? minStock}) {
    return BranchStock(
      branchId: branchId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
    );
  }
}

/// Inventory state holding live stocks across all branches
class InventoryState {
  const InventoryState({
    this.stocks = const {},
  });

  /// Key: '$branchId:$productId' -> quantity
  final Map<String, int> stocks;

  int getStock(String branchId, String productId) {
    return stocks['$branchId:$productId'] ?? 0;
  }

  bool isLowStock(String branchId, MockProduct product) {
    final qty = getStock(branchId, product.id);
    return qty <= product.minStock;
  }

  InventoryState copyWith({Map<String, int>? stocks}) {
    return InventoryState(stocks: stocks ?? this.stocks);
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    loadAllBranchStocks();
    return const InventoryState(stocks: {});
  }

  /// Load stock for all branches from PostgreSQL backend
  Future<void> loadAllBranchStocks() async {
    final branchKeys = kBranches.keys.toList();
    for (final bKey in branchKeys) {
      await loadBranchStock(bKey);
    }
  }

  /// Bulk-update stocks map (called by CatalogNotifier when /products returns branch_stocks)
  void applyBranchStocksFromProducts(List<Map<String, dynamic>> rawProducts) {
    final next = Map<String, int>.from(state.stocks);
    for (final map in rawProducts) {
      final id = map['id']?.toString() ?? '';
      final sku = map['sku']?.toString() ?? '';
      final branchStocks = map['branch_stocks'];
      if (branchStocks is Map) {
        branchStocks.forEach((rawBranchId, rawQty) {
          final bKey = normalizeBranchId(rawBranchId.toString());
          final qty = (rawQty is num)
              ? rawQty.toInt()
              : double.tryParse(rawQty?.toString() ?? '')?.toInt() ?? 0;
          if (id.isNotEmpty) {
            next['$bKey:$id'] = qty;
            next['$rawBranchId:$id'] = qty;
          }
          if (sku.isNotEmpty) {
            next['$bKey:$sku'] = qty;
            next['$rawBranchId:$sku'] = qty;
          }
        });
      }
    }
    state = state.copyWith(stocks: next);
  }

  /// Load live stock quantities for a specific branch from backend
  Future<void> loadBranchStock(String branchId) async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/products', queryParams: {'branchId': branchId});
      if (data is List && data.isNotEmpty) {
        final next = Map<String, int>.from(state.stocks);
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final sku = map['sku']?.toString() ?? '';
          final qty = (map['stock_quantity'] is num)
              ? (map['stock_quantity'] as num).toInt()
              : double.tryParse(map['stock_quantity']?.toString() ?? '')?.toInt() ?? 0;
          if (id.isNotEmpty) next['$branchId:$id'] = qty;
          if (sku.isNotEmpty) next['$branchId:$sku'] = qty;
        }
        state = state.copyWith(stocks: next);
      }
    } catch (_) {}
  }

  /// Deduct stock for a product at a branch (e.g. sale, wastage, outgoing transfer)
  bool deductStock(String branchId, String productId, int quantity) {
    final key = '$branchId:$productId';
    final current = state.stocks[key] ?? 0;
    if (quantity > current) {
      return false; // Insufficient stock
    }
    final next = Map<String, int>.from(state.stocks);
    next[key] = current - quantity;
    state = state.copyWith(stocks: next);
    return true;
  }

  /// Add stock for a product at a branch (e.g. transfer receipt, restock, void)
  void addStock(String branchId, String productId, int quantity) {
    final key = '$branchId:$productId';
    final current = state.stocks[key] ?? 0;
    final next = Map<String, int>.from(state.stocks);
    next[key] = current + quantity;
    state = state.copyWith(stocks: next);
  }

  /// Updates local stock map without triggering a remote API call
  void setLocalStock(String branchId, String productId, int quantity) {
    final key = '$branchId:$productId';
    final next = Map<String, int>.from(state.stocks);
    next[key] = quantity.clamp(0, 999999);
    state = state.copyWith(stocks: next);
  }

  /// Directly set stock quantity (manual stock take adjustment) with backend sync.
  /// Returns true only if the backend API request succeeds.
  Future<bool> setStock(String branchId, String productId, int quantity) async {
    final prev = getStockFor(branchId, productId);
    setLocalStock(branchId, productId, quantity);

    try {
      final client = ref.read(apiClientProvider);
      await client.post('/inventory/adjust', body: {
        'branchId': branchId,
        'productId': productId,
        'newQuantity': quantity,
      });
      return true;
    } catch (_) {
      setLocalStock(branchId, productId, prev);
      return false;
    }
  }

  int getStockFor(String branchId, String productId) =>
      state.getStock(branchId, productId);
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

final catalogLoadingProvider = StateProvider<bool>((ref) => true);

/// Catalog notifier holding the active product catalog across the app
class CatalogNotifier extends Notifier<List<MockProduct>> {
  @override
  List<MockProduct> build() {
    loadProducts();
    return const [];
  }

  /// Load products catalog from remote PostgreSQL backend
  Future<void> loadProducts() async {
    ref.read(catalogLoadingProvider.notifier).state = true;
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/products');
      if (data is List) {
        final rawMaps = data.whereType<Map<String, dynamic>>().toList();
        final seenIds = <String>{};
        final prods = <MockProduct>[];
        for (final map in rawMaps) {
          final prod = MockProduct.fromJson(map);
          if (seenIds.add(prod.id)) {
            prods.add(prod);
          }
        }
        state = prods;
        ref.read(inventoryProvider.notifier).applyBranchStocksFromProducts(rawMaps);
        await ref.read(inventoryProvider.notifier).loadAllBranchStocks();
      }
    } catch (_) {
    } finally {
      ref.read(catalogLoadingProvider.notifier).state = false;
    }
  }

  /// Adds a new product to the catalog and seeds its initial branch stocks sequentially (LIFO).
  /// Returns true only if the backend API call succeeds.
  Future<bool> addProduct(
    MockProduct product, {
    int stockBranchA = 0,
    int stockBranchB = 0,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final created = await client.post('/products', body: {
        'categoryId': product.categoryId ?? product.categoryName ?? product.category.name,
        'subcategory': product.subcategory,
        'name': product.name,
        'sku': product.sku,
        'barcode': product.barcode,
        'costPrice': product.costPrice,
        'salePrice': product.salePrice,
        'originType': product.originType?.name,
        'sizeLabel': product.sizeLabel,
        'initialStock': stockBranchA,
        'branchId': 'branch_a',
        'attributes': {
          'imageEmoji': product.imageEmoji,
          if (product.customImagePath != null) 'customImagePath': product.customImagePath,
        },
      });

      final createdId = (created is Map && created['id'] != null)
          ? created['id'].toString()
          : product.sku;

      if (stockBranchB > 0) {
        await client.post('/inventory/adjust', body: {
          'branchId': 'branch_b',
          'productId': createdId,
          'newQuantity': stockBranchB,
        });
      }

      await loadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates an existing product in the catalog and optionally updates branch stocks.
  /// Returns true only if the backend API call succeeds.
  Future<bool> updateProduct(
    MockProduct updated, {
    int? stockBranchA,
    int? stockBranchB,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/products/${updated.id}', body: {
        'categoryId': updated.categoryId ?? updated.categoryName ?? updated.category.name,
        'subcategory': updated.subcategory,
        'name': updated.name,
        'sku': updated.sku,
        'barcode': updated.barcode,
        'costPrice': updated.costPrice,
        'salePrice': updated.salePrice,
        'sizeLabel': updated.sizeLabel,
        'originType': updated.originType?.name,
        'attributes': {
          'imageEmoji': updated.imageEmoji,
          if (updated.customImagePath != null) 'customImagePath': updated.customImagePath,
        },
      });

      if (stockBranchA != null) {
        await client.post('/inventory/adjust', body: {
          'branchId': 'branch_a',
          'productId': updated.id,
          'newQuantity': stockBranchA,
        });
      }
      if (stockBranchB != null) {
        await client.post('/inventory/adjust', body: {
          'branchId': 'branch_b',
          'productId': updated.id,
          'newQuantity': stockBranchB,
        });
      }
      await loadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a product from the catalog.
  /// Returns true only if the backend API call succeeds.
  Future<bool> deleteProduct(String productId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/products/$productId');
      state = state.where((p) => p.id != productId).toList();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final catalogProvider =
    NotifierProvider<CatalogNotifier, List<MockProduct>>(CatalogNotifier.new);

/// Live product stock with product metadata for a given branch
class ProductWithStock {
  const ProductWithStock({
    required this.product,
    required this.stock,
    required this.branchId,
  });

  final MockProduct product;
  final int stock;
  final String branchId;

  bool get isLowStock => stock <= product.minStock;
  bool get isOutOfStock => stock <= 0;
}

/// Provider of products with live branch stock
final branchInventoryProvider =
    Provider.family<List<ProductWithStock>, String>((ref, branchId) {
  final products = ref.watch(catalogProvider);
  final inv = ref.watch(inventoryProvider);
  return products.map((p) {
    final stock = inv.getStock(branchId, p.id);
    return ProductWithStock(
      product: p,
      stock: stock,
      branchId: branchId,
    );
  }).toList();
});

/// Provider of low stock products for a given branch
final lowStockAlertProvider =
    Provider.family<List<ProductWithStock>, String?>((ref, branchId) {
  final products = ref.watch(catalogProvider);
  final inv = ref.watch(inventoryProvider);
  final List<ProductWithStock> result = [];

  final branchesToCheck = branchId == null || branchId == 'all'
      ? ['branch_a', 'branch_b']
      : [branchId];

  for (final bId in branchesToCheck) {
    for (final p in products) {
      final stock = inv.getStock(bId, p.id);
      if (stock <= p.minStock) {
        result.add(ProductWithStock(product: p, stock: stock, branchId: bId));
      }
    }
  }

  return result;
});
