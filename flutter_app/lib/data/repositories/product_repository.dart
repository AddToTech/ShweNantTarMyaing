// lib/data/repositories/product_repository.dart

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/drift/app_database.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/product.dart';
import '../mock/mock_products.dart' show kBranchKeyToUuid;

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return ProductRepository(apiClient: apiClient, db: db);
});

class ProductRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;

  ProductRepository({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  static OriginType? _parseOriginType(dynamic val) {
    if (val == null) return null;
    final str = val.toString().toLowerCase().replaceAll('_', '');
    if (str.contains('thai')) return OriginType.thaiImport;
    if (str.contains('china')) return OriginType.chinaImport;
    if (str.contains('local')) return OriginType.local;
    return null;
  }

  static Product _productFromMap(Map<String, dynamic> map) {
    Map<String, dynamic> attributes = {};
    if (map['attributes'] != null) {
      if (map['attributes'] is Map) {
        attributes = Map<String, dynamic>.from(map['attributes'] as Map);
      } else if (map['attributes'] is String) {
        try {
          attributes = jsonDecode(map['attributes'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    if (map['image_url'] != null && map['image_url'].toString().isNotEmpty) {
      attributes['customImagePath'] = map['image_url'];
    }

    return Product(
      id: map['id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      subcategoryId: map['subcategory_id']?.toString(),
      name: map['name']?.toString() ?? '',
      sku: map['sku']?.toString(),
      barcode: map['barcode']?.toString(),
      costPrice: (map['cost_price'] is num) ? (map['cost_price'] as num).toDouble() : double.tryParse(map['cost_price']?.toString() ?? '') ?? 0.0,
      salePrice: (map['sale_price'] is num) ? (map['sale_price'] as num).toDouble() : double.tryParse(map['sale_price']?.toString() ?? '') ?? 0.0,
      originType: _parseOriginType(map['origin_type']),
      sizeLabel: map['size_label']?.toString(),
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'].toString()) : null,
      unitOfMeasure: map['unit_of_measure']?.toString() ?? 'piece',
      attributes: attributes,
      isActive: map['is_active'] != false,
    );
  }

  /// Get categories and their subcategories
  Future<List<Category>> getCategories() async {
    try {
      final data = await _apiClient.get('/categories');
      if (data is List) {
        final categories = data.map((c) {
          final catMap = c as Map<String, dynamic>;
          final catId = catMap['id']?.toString() ?? '';
          final subList = (catMap['subcategories'] as List? ?? []).map((s) {
            final subMap = s as Map<String, dynamic>;
            return Subcategory(
              id: subMap['id']?.toString() ?? '',
              categoryId: subMap['category_id']?.toString() ?? catId,
              name: subMap['name']?.toString() ?? '',
              sortOrder: (subMap['sort_order'] as num?)?.toInt() ?? 0,
            );
          }).toList();

          return Category(
            id: catId,
            name: catMap['name']?.toString() ?? '',
            sortOrder: (catMap['sort_order'] as num?)?.toInt() ?? 0,
            subcategories: subList,
          );
        }).toList();

        // Update local drift cache
        try {
          final catCompanions = categories.map((c) => CategoriesCacheCompanion.insert(
            id: c.id,
            name: c.name,
            sortOrder: Value(c.sortOrder),
            updatedAt: DateTime.now(),
          )).toList();
          await _db.syncCategories(catCompanions);
        } catch (_) {}

        return categories;
      }
    } catch (_) {
      // Local cache fallback
      final cachedCats = await _db.select(_db.categoriesCache).get();
      if (cachedCats.isNotEmpty) {
        final cachedSubs = await _db.select(_db.subcategoriesCache).get();
        return cachedCats.map((c) {
          final subs = cachedSubs
              .where((s) => s.categoryId == c.id)
              .map((s) => Subcategory(
                    id: s.id,
                    categoryId: s.categoryId,
                    name: s.name,
                    sortOrder: s.sortOrder,
                  ))
              .toList();
          return Category(id: c.id, name: c.name, sortOrder: c.sortOrder, subcategories: subs);
        }).toList();
      }
    }
    return const [];
  }

  /// Get list of branch inventory items (products + branch stock)
  Future<List<BranchInventory>> getProductsWithInventory({
    required String branchId,
    String? categoryId,
    String? originType,
    String? search,
  }) async {
    try {
      final actualBranchId = kBranchKeyToUuid[branchId] ?? branchId;
      final queryParams = <String, dynamic>{'branchId': actualBranchId};
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        queryParams['categoryId'] = categoryId;
      }
      if (originType != null && originType.isNotEmpty && originType != 'all') {
        queryParams['originType'] = originType;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final data = await _apiClient.get('/products', queryParams: queryParams);
      if (data is List) {
        final items = data.map((item) {
          final map = item as Map<String, dynamic>;
          final product = _productFromMap(map);
          final stockQty = (map['stock_quantity'] is num)
              ? (map['stock_quantity'] as num).toDouble()
              : double.tryParse(map['stock_quantity']?.toString() ?? '') ?? 0.0;
          final minThreshold = (map['min_alert_threshold'] is num)
              ? (map['min_alert_threshold'] as num).toDouble()
              : double.tryParse(map['min_alert_threshold']?.toString() ?? '') ?? 5.0;

          return BranchInventory(
            id: '${branchId}_${product.id}',
            branchId: branchId,
            productId: product.id,
            product: product,
            stockQuantity: stockQty,
            minAlertThreshold: minThreshold,
          );
        }).toList();

        // Background update local cache
        try {
          final prodRows = items.map((bi) => ProductsCacheCompanion.insert(
            id: bi.product.id,
            categoryId: bi.product.categoryId,
            subcategoryId: Value(bi.product.subcategoryId),
            name: bi.product.name,
            sku: Value(bi.product.sku),
            barcode: Value(bi.product.barcode),
            costPrice: Value(bi.product.costPrice),
            salePrice: Value(bi.product.salePrice),
            originType: Value(bi.product.originType?.name),
            sizeLabel: Value(bi.product.sizeLabel),
            unitOfMeasure: Value(bi.product.unitOfMeasure),
            attributesJson: Value(jsonEncode(bi.product.attributes)),
            isActive: Value(bi.product.isActive),
            updatedAt: DateTime.now(),
          )).toList();

          final invRows = items.map((bi) => BranchInventoriesCacheCompanion.insert(
            id: bi.id,
            branchId: bi.branchId,
            productId: bi.productId,
            stockQuantity: Value(bi.stockQuantity),
            minAlertThreshold: Value(bi.minAlertThreshold),
            updatedAt: DateTime.now(),
          )).toList();

          await _db.syncProducts(prodRows);
          await _db.syncInventories(invRows);
        } catch (_) {}

        return items;
      }
    } catch (_) {
      // Local cache fallback
      final cachedProds = await _db.select(_db.productsCache).get();
      final cachedInvs = await _db.select(_db.branchInventoriesCache).get();

      if (cachedProds.isNotEmpty) {
        return cachedProds.map((cp) {
          final inv = cachedInvs.where((i) => i.productId == cp.id && i.branchId == branchId).firstOrNull;
          Map<String, dynamic> attrs = {};
          try {
            attrs = jsonDecode(cp.attributesJson) as Map<String, dynamic>;
          } catch (_) {}

          final p = Product(
            id: cp.id,
            categoryId: cp.categoryId,
            subcategoryId: cp.subcategoryId,
            name: cp.name,
            sku: cp.sku,
            barcode: cp.barcode,
            costPrice: cp.costPrice,
            salePrice: cp.salePrice,
            originType: _parseOriginType(cp.originType),
            sizeLabel: cp.sizeLabel,
            unitOfMeasure: cp.unitOfMeasure,
            attributes: attrs,
            isActive: cp.isActive,
          );

          return BranchInventory(
            id: inv?.id ?? '${branchId}_${p.id}',
            branchId: branchId,
            productId: p.id,
            product: p,
            stockQuantity: inv?.stockQuantity ?? 0.0,
            minAlertThreshold: inv?.minAlertThreshold ?? 5.0,
          );
        }).toList();
      }
    }
    return const [];
  }

  /// Create new product
  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _apiClient.post('/products', body: payload);
    return _productFromMap(data as Map<String, dynamic>);
  }

  /// Update existing product
  Future<Product> updateProduct(String id, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch('/products/$id', body: payload);
    return _productFromMap(data as Map<String, dynamic>);
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/products/$id');
  }

  /// Upload product image
  Future<String> uploadImage(String productId, String filePath) async {
    final data = await _apiClient.multipartPost(
      '/products/$productId/image',
      fileFieldName: 'image',
      filePath: filePath,
    );
    if (data is Map && data['image_url'] != null) {
      return data['image_url'].toString();
    }
    return '';
  }
}

