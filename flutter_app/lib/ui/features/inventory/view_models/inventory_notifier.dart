import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/mock/mock_products.dart';
import '../../settings/view_models/plant_origin_notifier.dart';

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
    this.exactStocks = const {},
    this.approxStocks = const {},
  });

  /// Key: '$branchId:$productId' -> integer quantity (for backward compatibility)
  final Map<String, int> stocks;

  /// Key: '$branchId:$productId' -> exact decimal quantity (supports fractional Kg)
  final Map<String, double> exactStocks;

  /// Key: '$branchId:$productId' -> approximate piece quantity for Kg products
  final Map<String, int> approxStocks;

  int getStock(String branchId, String productId) {
    return stocks['$branchId:$productId'] ?? 0;
  }

  double getExactStock(String branchId, String productId) {
    final key = '$branchId:$productId';
    return exactStocks[key] ?? (stocks[key]?.toDouble() ?? 0.0);
  }

  int getApproxStock(String branchId, String productId) {
    return approxStocks['$branchId:$productId'] ?? 0;
  }

  bool isLowStock(String branchId, MockProduct product) {
    final qty = getExactStock(branchId, product.id);
    return qty <= product.minStock;
  }

  InventoryState copyWith({
    Map<String, int>? stocks,
    Map<String, double>? exactStocks,
    Map<String, int>? approxStocks,
  }) {
    return InventoryState(
      stocks: stocks ?? this.stocks,
      exactStocks: exactStocks ?? this.exactStocks,
      approxStocks: approxStocks ?? this.approxStocks,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    loadAllBranchStocks();
    return const InventoryState();
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
    final nextExact = Map<String, double>.from(state.exactStocks);
    final nextApprox = Map<String, int>.from(state.approxStocks);
    for (final map in rawProducts) {
      final id = map['id']?.toString() ?? '';
      final sku = map['sku']?.toString() ?? '';
      final branchStocks = map['branch_stocks'];
      if (branchStocks is Map) {
        branchStocks.forEach((rawBranchId, rawQty) {
          final bKey = normalizeBranchId(rawBranchId.toString());
          final exact = (rawQty is num)
              ? rawQty.toDouble()
              : double.tryParse(rawQty?.toString() ?? '') ?? 0.0;
          final qty = exact.round();
          if (id.isNotEmpty) {
            next['$bKey:$id'] = qty;
            next['$rawBranchId:$id'] = qty;
            nextExact['$bKey:$id'] = exact;
            nextExact['$rawBranchId:$id'] = exact;
          }
          if (sku.isNotEmpty) {
            next['$bKey:$sku'] = qty;
            next['$rawBranchId:$sku'] = qty;
            nextExact['$bKey:$sku'] = exact;
            nextExact['$rawBranchId:$sku'] = exact;
          }
        });
      }
      final branchApprox = map['branch_approx_stocks'];
      if (branchApprox is Map) {
        branchApprox.forEach((rawBranchId, rawApprox) {
          final bKey = normalizeBranchId(rawBranchId.toString());
          final approx = (rawApprox is num)
              ? rawApprox.toInt()
              : int.tryParse(rawApprox?.toString() ?? '') ?? 0;
          if (id.isNotEmpty) {
            nextApprox['$bKey:$id'] = approx;
            nextApprox['$rawBranchId:$id'] = approx;
          }
        });
      }
    }
    state = state.copyWith(
      stocks: next,
      exactStocks: nextExact,
      approxStocks: nextApprox,
    );
  }

  /// Load live stock quantities for a specific branch from backend
  Future<void> loadBranchStock(String branchId) async {
    try {
      final client = ref.read(apiClientProvider);
      final actualBranchId = kBranchKeyToUuid[branchId] ?? branchId;
      final data = await client.get('/products', queryParams: {'branchId': actualBranchId});
      if (data is List && data.isNotEmpty) {
        final next = Map<String, int>.from(state.stocks);
        final nextExact = Map<String, double>.from(state.exactStocks);
        final nextApprox = Map<String, int>.from(state.approxStocks);
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final sku = map['sku']?.toString() ?? '';
          final exact = (map['stock_quantity'] is num)
              ? (map['stock_quantity'] as num).toDouble()
              : double.tryParse(map['stock_quantity']?.toString() ?? '') ?? 0.0;
          final qty = exact.round();
          final approx = (map['approximate_quantity'] is num)
              ? (map['approximate_quantity'] as num).toInt()
              : int.tryParse(map['approximate_quantity']?.toString() ?? '') ?? 0;
          if (id.isNotEmpty) {
            next['$branchId:$id'] = qty;
            nextExact['$branchId:$id'] = exact;
            nextApprox['$branchId:$id'] = approx;
          }
          if (sku.isNotEmpty) {
            next['$branchId:$sku'] = qty;
            nextExact['$branchId:$sku'] = exact;
          }
        }
        state = state.copyWith(
          stocks: next,
          exactStocks: nextExact,
          approxStocks: nextApprox,
        );
      }
    } catch (_) {}
  }

  /// Deduct stock for a product at a branch (e.g. sale, wastage, outgoing transfer)
  bool deductStock(String branchId, String productId, int quantity) {
    return deductStockExact(branchId, productId, quantity.toDouble());
  }

  /// Deduct fractional (Kg) stock and optional approximate quantity at a branch
  bool deductStockExact(
    String branchId,
    String productId,
    double quantity, {
    int? approximateQuantity,
  }) {
    final key = '$branchId:$productId';
    final currentExact = state.getExactStock(branchId, productId);
    if (quantity > currentExact + 0.0001) {
      return false; // Insufficient stock
    }
    final nextExactVal = (currentExact - quantity).clamp(0.0, 999999.0);
    final next = Map<String, int>.from(state.stocks);
    final nextExact = Map<String, double>.from(state.exactStocks);
    nextExact[key] = nextExactVal;
    next[key] = nextExactVal.round();

    Map<String, int>? nextApprox;
    if (approximateQuantity != null && approximateQuantity > 0) {
      nextApprox = Map<String, int>.from(state.approxStocks);
      final currentApprox = nextApprox[key] ?? 0;
      nextApprox[key] = (currentApprox - approximateQuantity).clamp(0, 999999);
    }

    state = state.copyWith(
      stocks: next,
      exactStocks: nextExact,
      approxStocks: nextApprox,
    );
    return true;
  }

  /// Add stock for a product at a branch (e.g. transfer receipt, restock, void)
  void addStock(String branchId, String productId, int quantity) {
    addStockExact(branchId, productId, quantity.toDouble());
  }

  /// Add fractional (Kg) stock and optional approximate quantity at a branch
  void addStockExact(
    String branchId,
    String productId,
    double quantity, {
    int? approximateQuantity,
  }) {
    final key = '$branchId:$productId';
    final currentExact = state.getExactStock(branchId, productId);
    final nextExactVal = (currentExact + quantity).clamp(0.0, 999999.0);
    final next = Map<String, int>.from(state.stocks);
    final nextExact = Map<String, double>.from(state.exactStocks);
    nextExact[key] = nextExactVal;
    next[key] = nextExactVal.round();

    Map<String, int>? nextApprox;
    if (approximateQuantity != null && approximateQuantity > 0) {
      nextApprox = Map<String, int>.from(state.approxStocks);
      nextApprox[key] = (nextApprox[key] ?? 0) + approximateQuantity;
    }

    state = state.copyWith(
      stocks: next,
      exactStocks: nextExact,
      approxStocks: nextApprox,
    );
  }

  /// Updates local stock map without triggering a remote API call
  void setLocalStock(String branchId, String productId, num quantity,
      {int? approximateQuantity}) {
    final key = '$branchId:$productId';
    final clamped = quantity.toDouble().clamp(0.0, 999999.0);
    final next = Map<String, int>.from(state.stocks);
    final nextExact = Map<String, double>.from(state.exactStocks);
    nextExact[key] = clamped;
    next[key] = clamped.round();

    Map<String, int>? nextApprox;
    if (approximateQuantity != null) {
      nextApprox = Map<String, int>.from(state.approxStocks);
      nextApprox[key] = approximateQuantity.clamp(0, 999999);
    }

    state = state.copyWith(
      stocks: next,
      exactStocks: nextExact,
      approxStocks: nextApprox,
    );
  }

  /// Directly set stock quantity (supports decimal Kg and optional approximateQuantity) with backend sync.
  /// Returns true only if the backend API request succeeds.
  Future<bool> setStock(String branchId, String productId, num quantity,
      {int? approximateQuantity}) async {
    final prevExact = state.getExactStock(branchId, productId);
    final prevApprox = state.getApproxStock(branchId, productId);
    setLocalStock(branchId, productId, quantity,
        approximateQuantity: approximateQuantity);

    try {
      final client = ref.read(apiClientProvider);
      await client.post('/inventory/adjust', body: {
        'branchId': branchId,
        'productId': productId,
        'newQuantity': quantity,
        if (approximateQuantity != null) 'approximateQuantity': approximateQuantity,
      });
      return true;
    } catch (_) {
      setLocalStock(
        branchId,
        productId,
        prevExact,
        approximateQuantity: approximateQuantity != null ? prevApprox : null,
      );
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

  bool _isLocalUploadableImage(String? path) {
    if (kIsWeb || path == null) return false;
    final p = path.trim();
    if (p.isEmpty || AppConstants.isRemoteMediaPath(p) || p.startsWith('assets/')) {
      return false;
    }
    return File(p).existsSync();
  }

  Future<void> _uploadProductImageIfPresent(
    ApiClient client,
    String productId,
    String? imagePath,
  ) async {
    if (!_isLocalUploadableImage(imagePath)) return;
    try {
      await client.multipartPost(
        '/products/$productId/image',
        fileFieldName: 'image',
        filePath: imagePath!.trim(),
      );
    } catch (_) {
      // ApiClient.multipartPost already triggers AppToast on failure.
    }
  }

  /// Adds a new product to the catalog and seeds its initial branch stocks sequentially (LIFO).
  /// Returns true only if the backend API call succeeds.
  Future<bool> addProduct(
    MockProduct product, {
    Map<String, int> branchStocks = const {},
    Map<String, double> exactBranchStocks = const {},
    Map<String, int> branchApproxStocks = const {},
    int stockBranchA = 0,
    int stockBranchB = 0,
  }) async {
    try {
      final client = ref.read(apiClientProvider);

      final finalStocks = <String, num>{
        if (exactBranchStocks.isNotEmpty)
          ...exactBranchStocks
        else
          ...branchStocks,
      };
      if (stockBranchA > 0 && !finalStocks.containsKey('branch_a')) {
        finalStocks['branch_a'] = stockBranchA;
      }
      if (stockBranchB > 0 && !finalStocks.containsKey('branch_b')) {
        finalStocks['branch_b'] = stockBranchB;
      }

      final firstBranchId = finalStocks.keys.firstOrNull ?? 'branch_a';
      final firstStock = finalStocks[firstBranchId] ?? 0;
      final rawImagePath = product.customImagePath?.trim();
      final isRemoteImage = AppConstants.isRemoteMediaPath(rawImagePath);
      final isAssetImage = rawImagePath != null && rawImagePath.startsWith('assets/');

      final created = await client.post('/products', body: {
        'categoryId': product.categoryId ?? product.categoryName ?? product.category.name,
        'subcategory': product.subcategory,
        'name': product.name,
        'sku': product.sku,
        'barcode': product.barcode,
        'costPrice': product.costPrice,
        'salePrice': product.salePrice,
        'originType': product.originName ?? product.originType?.name,
        'originId': product.originId,
        'sizeLabel': product.sizeLabel,
        'vendorId': product.vendorId,
        'unitOfMeasure': product.unitOfMeasure,
        'initialStock': firstStock,
        'branchId': firstBranchId,
        'branchStocks': finalStocks,
        if (branchApproxStocks.isNotEmpty) 'branchApproxStocks': branchApproxStocks,
        if (isRemoteImage) 'imageUrl': rawImagePath,
        'attributes': {
          'imageEmoji': product.imageEmoji,
          if (isAssetImage) 'customImagePath': rawImagePath,
          if (product.approximateQuantity != null)
            'approximateQuantity': product.approximateQuantity,
        },
      });

      final createdId = (created is Map && created['id'] != null)
          ? created['id'].toString()
          : product.sku;

      if (created is Map && created['id'] != null) {
        await _uploadProductImageIfPresent(client, createdId, rawImagePath);
      }

      for (final entry in finalStocks.entries) {
        if (entry.key == firstBranchId) continue;
        final approx = branchApproxStocks[entry.key];
        if (entry.value > 0 || (approx != null && approx > 0)) {
          await client.post('/inventory/adjust', body: {
            'branchId': entry.key,
            'productId': createdId,
            'newQuantity': entry.value,
            if (approx != null) 'approximateQuantity': approx,
          });
        }
      }

      await loadProducts();
      ref.read(plantOriginProvider.notifier).loadOrigins();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates an existing product in the catalog and optionally updates branch stocks.
  /// Returns true only if the backend API call succeeds.
  Future<bool> updateProduct(
    MockProduct updated, {
    Map<String, int> branchStocks = const {},
    Map<String, double> exactBranchStocks = const {},
    Map<String, int> branchApproxStocks = const {},
    int? stockBranchA,
    int? stockBranchB,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final rawImagePath = updated.customImagePath?.trim();
      final isCleared = rawImagePath == null || rawImagePath.isEmpty;
      final isRemote = AppConstants.isRemoteMediaPath(rawImagePath);
      final isAsset = rawImagePath != null && rawImagePath.startsWith('assets/');
      final isLocalExisting = _isLocalUploadableImage(rawImagePath);
      final isUnresolvableLegacyPath =
          !isCleared && !isRemote && !isAsset && !isLocalExisting;

      await client.patch('/products/${updated.id}', body: {
        'categoryId': updated.categoryId ?? updated.categoryName ?? updated.category.name,
        'subcategory': updated.subcategory,
        'name': updated.name,
        'sku': updated.sku,
        'barcode': updated.barcode,
        'costPrice': updated.costPrice,
        'salePrice': updated.salePrice,
        'sizeLabel': updated.sizeLabel,
        'originType': updated.originName ?? updated.originType?.name,
        'originId': updated.originId,
        'vendorId': updated.vendorId,
        'unitOfMeasure': updated.unitOfMeasure,
        if (isCleared || isAsset) 'imageUrl': null,
        if (isRemote) 'imageUrl': rawImagePath,
        'attributes': {
          'imageEmoji': updated.imageEmoji,
          if (isAsset || isUnresolvableLegacyPath) 'customImagePath': rawImagePath,
          if (updated.approximateQuantity != null)
            'approximateQuantity': updated.approximateQuantity,
        },
      });

      if (isLocalExisting) {
        await _uploadProductImageIfPresent(client, updated.id, rawImagePath);
      }

      final finalStocks = <String, num>{
        if (exactBranchStocks.isNotEmpty)
          ...exactBranchStocks
        else
          ...branchStocks,
      };
      if (stockBranchA != null && !finalStocks.containsKey('branch_a')) {
        finalStocks['branch_a'] = stockBranchA;
      }
      if (stockBranchB != null && !finalStocks.containsKey('branch_b')) {
        finalStocks['branch_b'] = stockBranchB;
      }

      for (final entry in finalStocks.entries) {
        final approx = branchApproxStocks[entry.key];
        await client.post('/inventory/adjust', body: {
          'branchId': entry.key,
          'productId': updated.id,
          'newQuantity': entry.value,
          if (approx != null) 'approximateQuantity': approx,
        });
      }

      await loadProducts();
      ref.read(plantOriginProvider.notifier).loadOrigins();
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
      ref.read(plantOriginProvider.notifier).loadOrigins();
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
    this.exactStock,
    this.approximateQty = 0,
    required this.branchId,
  });

  final MockProduct product;
  final int stock;
  final double? exactStock;
  final int approximateQty;
  final String branchId;

  double get displayStock => exactStock ?? stock.toDouble();
  bool get isLowStock => displayStock <= product.minStock;
  bool get isOutOfStock => displayStock <= 0;
}

/// Provider of products with live branch stock
final branchInventoryProvider =
    Provider.family<List<ProductWithStock>, String>((ref, branchId) {
  final products = ref.watch(catalogProvider);
  final inv = ref.watch(inventoryProvider);
  return products.map((p) {
    final stock = inv.getStock(branchId, p.id);
    final exactStock = inv.getExactStock(branchId, p.id);
    final approxQty = inv.getApproxStock(branchId, p.id);
    return ProductWithStock(
      product: p,
      stock: stock,
      exactStock: exactStock,
      approximateQty: approxQty,
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
      final exactStock = inv.getExactStock(bId, p.id);
      if (exactStock <= p.minStock) {
        result.add(ProductWithStock(
          product: p,
          stock: exactStock.round(),
          exactStock: exactStock,
          approximateQty: inv.getApproxStock(bId, p.id),
          branchId: bId,
        ));
      }
    }
  }

  return result;
});
