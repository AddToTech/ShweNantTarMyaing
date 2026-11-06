// ============================================================
// Product model & catalog (synced with PostgreSQL backend)
// ============================================================

import 'dart:convert';

enum ProductCategory { all, plants, pots, chemicals, tools, others }

enum OriginType { thaiImport, chinaImport, local }

extension OriginTypeX on OriginType {
  String get burmeseLabel => switch (this) {
        OriginType.thaiImport => 'ယိုးဒယား Import',
        OriginType.chinaImport => 'တရုတ် Import',
        OriginType.local => 'ပြည်တွင်း',
      };

  String get shortLabel => switch (this) {
        OriginType.thaiImport => 'ယိုးဒယား',
        OriginType.chinaImport => 'တရုတ်',
        OriginType.local => 'ပြည်တွင်း',
      };
}

class MockProduct {
  const MockProduct({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId,
    this.categoryName,
    this.subcategory = '',
    required this.salePrice,
    required this.costPrice,
    required this.stock,
    this.minStock = 5,
    this.originType,
    this.sizeLabel,
    this.vendorId,
    this.vendorName,
    this.imageEmoji = '🌿',
    this.customImagePath,
    this.sku = '',
    this.barcode,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final String? categoryId;
  final String? categoryName;
  final String subcategory;
  final double salePrice;
  final double costPrice;
  final int stock;
  final int minStock;
  final OriginType? originType;
  final String? sizeLabel;
  final String? vendorId;
  final String? vendorName;
  final String imageEmoji;
  final String? customImagePath;
  final String sku;
  final String? barcode;

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock == 0;

  static bool isBuiltInCategoryName(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('plant') ||
        lower.contains('အပင်') ||
        lower.contains('pot') ||
        lower.contains('အိုး') ||
        lower.contains('chem') ||
        lower.contains('ဆေး') ||
        lower.contains('မြေသြဇာ') ||
        lower.contains('tool') ||
        lower.contains('ကိရိယာ') ||
        lower.contains('other') ||
        lower.contains('အခြား');
  }

  /// Checks whether this product belongs to a category (supports both built-in and custom categories)
  bool matchesCategory({
    required String selectedCategoryId,
    ProductCategory? standardCategory,
    String? catName,
    String? catEnglishName,
  }) {
    if (selectedCategoryId == 'all') return true;
    if (categoryId != null && categoryId!.isNotEmpty && categoryId == selectedCategoryId) {
      return true;
    }
    if (categoryName != null && categoryName!.isNotEmpty) {
      final prodCatLower = categoryName!.toLowerCase();
      if (catName != null && catName.isNotEmpty && prodCatLower == catName.toLowerCase()) {
        return true;
      }
      if (catEnglishName != null &&
          catEnglishName.isNotEmpty &&
          prodCatLower == catEnglishName.toLowerCase()) {
        return true;
      }
    }
    if (standardCategory != null && standardCategory != ProductCategory.all) {
      if (categoryName != null &&
          categoryName!.isNotEmpty &&
          !isBuiltInCategoryName(categoryName!)) {
        return false;
      }
      return category == standardCategory;
    }
    return false;
  }

  MockProduct copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    String? categoryId,
    String? categoryName,
    String? subcategory,
    double? salePrice,
    double? costPrice,
    int? stock,
    int? minStock,
    OriginType? originType,
    String? sizeLabel,
    String? vendorId,
    String? vendorName,
    String? imageEmoji,
    String? customImagePath,
    bool clearCustomImage = false,
    String? sku,
    String? barcode,
  }) {
    return MockProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      originType: originType ?? this.originType,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      customImagePath: clearCustomImage ? null : (customImagePath ?? this.customImagePath),
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
    );
  }

  factory MockProduct.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Category
    final rawCatId = (json['category_id'] ?? json['categoryId'])?.toString();
    final rawCatName = (json['category_name'] ?? json['categoryName'])?.toString();
    final catName = rawCatName?.toLowerCase() ?? '';
    ProductCategory cat = ProductCategory.plants;
    if (catName.contains('chem') || catName.contains('ဆေး') || catName.contains('မြေသြဇာ')) {
      cat = ProductCategory.chemicals;
    } else if (catName.contains('plant') || catName.contains('အပင်')) {
      cat = ProductCategory.plants;
    } else if (catName.contains('pot') || catName.contains('အိုး')) {
      cat = ProductCategory.pots;
    } else if (catName.contains('tool') || catName.contains('ကိရိယာ')) {
      cat = ProductCategory.tools;
    } else if (catName.isNotEmpty) {
      cat = ProductCategory.others;
    }

    // 2. Resolve Origin Type
    OriginType? origin;
    final origStr = json['origin_type']?.toString().toLowerCase() ?? '';
    if (origStr.contains('thai')) {
      origin = OriginType.thaiImport;
    } else if (origStr.contains('china')) {
      origin = OriginType.chinaImport;
    } else if (origStr.contains('local')) {
      origin = OriginType.local;
    }

    // 3. Resolve Attributes (emoji, custom image)
    Map<String, dynamic> attrs = {};
    if (json['attributes'] is Map) {
      attrs = Map<String, dynamic>.from(json['attributes'] as Map);
    } else if (json['attributes'] is String) {
      try {
        attrs = jsonDecode(json['attributes'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    final emoji = attrs['imageEmoji']?.toString() ?? '🌿';
    final imagePath = json['image_url']?.toString() ?? attrs['customImagePath']?.toString();

    // 4. Resolve numbers
    final cost = (json['cost_price'] is num)
        ? (json['cost_price'] as num).toDouble()
        : double.tryParse(json['cost_price']?.toString() ?? '') ?? 0.0;
    final sale = (json['sale_price'] is num)
        ? (json['sale_price'] as num).toDouble()
        : double.tryParse(json['sale_price']?.toString() ?? '') ?? 0.0;
    final stockQty = (json['stock_quantity'] is num)
        ? (json['stock_quantity'] as num).toInt()
        : double.tryParse(json['stock_quantity']?.toString() ?? '')?.toInt() ?? 0;
    final minStockQty = (json['min_alert_threshold'] is num)
        ? (json['min_alert_threshold'] as num).toInt()
        : double.tryParse(json['min_alert_threshold']?.toString() ?? '')?.toInt() ?? 5;

    final rawVendorId = (json['vendor_id'] ?? json['vendorId'])?.toString();
    final rawVendorName = (json['vendor_name'] ?? json['vendorName'])?.toString();

    return MockProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: cat,
      categoryId: rawCatId,
      categoryName: rawCatName,
      subcategory: json['subcategory_name']?.toString() ?? '',
      salePrice: sale,
      costPrice: cost,
      stock: stockQty,
      minStock: minStockQty,
      originType: origin,
      sizeLabel: json['size_label']?.toString(),
      vendorId: rawVendorId,
      vendorName: rawVendorName,
      imageEmoji: emoji,
      customImagePath: imagePath,
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'subcategory': subcategory,
    'salePrice': salePrice,
    'costPrice': costPrice,
    'stock': stock,
    'minStock': minStock,
    'originType': originType?.name,
    'sizeLabel': sizeLabel,
    'vendorId': vendorId,
    'vendorName': vendorName,
    'imageEmoji': imageEmoji,
    'customImagePath': customImagePath,
    'sku': sku,
    'barcode': barcode,
  };
}

// ── Catalog (dynamically populated from GET /api/v1/products) ─────────────

const List<MockProduct> kMockProducts = [];

// ── Sub-filter definitions (dynamically populated from GET /api/v1/categories) ─

const Map<ProductCategory, List<String>> kSubFilters = {};

// ── Dynamic Branch definitions (synced from GET /api/v1/branches) ─────────

Map<String, String> kBranches = {
  'branch_a': 'SitePyoe Branch A',
  'branch_b': 'SitePyoe Branch B',
};

final Map<String, String> kBranchUuidToKey = {
  'bec6e204-8cd4-45f1-a668-3ca5ca8fb668': 'branch_a',
  '0ce4b895-992a-43e7-afff-04fc347d2a88': 'branch_b',
};

final Map<String, String> kBranchKeyToUuid = {
  'branch_a': 'bec6e204-8cd4-45f1-a668-3ca5ca8fb668',
  'branch_b': '0ce4b895-992a-43e7-afff-04fc347d2a88',
};

/// Normalizes a database branch UUID or branch name into the app's canonical branch key.
String normalizeBranchId(String? rawId, {String? branchName}) {
  if (rawId == null || rawId.isEmpty) return '';
  if (kBranches.containsKey(rawId)) return rawId;
  if (kBranchUuidToKey.containsKey(rawId)) return kBranchUuidToKey[rawId]!;

  final lowerId = rawId.toLowerCase();
  final lowerName = (branchName ?? '').toLowerCase();
  if (lowerId == 'bec6e204-8cd4-45f1-a668-3ca5ca8fb668' ||
      lowerName.contains('branch a') ||
      lowerName.contains('mingaladon') ||
      lowerName.contains('လှိုင်')) {
    return 'branch_a';
  }
  if (lowerId == '0ce4b895-992a-43e7-afff-04fc347d2a88' ||
      lowerName.contains('branch b') ||
      lowerName.contains('hledan') ||
      lowerName.contains('မြောက်ဒဂုံ')) {
    return 'branch_b';
  }
  return rawId;
}

/// Returns the backend database UUID for a given branchKey ('branch_a', 'branch_b' or direct UUID).
String resolveBranchUuid(String? branchKeyOrId) {
  if (branchKeyOrId == null || branchKeyOrId.isEmpty) return '';
  return kBranchKeyToUuid[branchKeyOrId] ?? branchKeyOrId;
}

/// Updates [kBranches] in-place from backend `/branches` records.
void updateDynamicBranchesFromApi(List<Map<String, dynamic>> rawBranches) {
  if (rawBranches.isEmpty) return;
  final Map<String, String> updated = {};
  for (var i = 0; i < rawBranches.length; i++) {
    final row = rawBranches[i];
    final id = row['id']?.toString() ?? '';
    final name = row['name']?.toString() ?? 'Branch ${i + 1}';
    final address = row['address']?.toString();
    final label = (address != null && address.trim().isNotEmpty)
        ? '$name ($address)'
        : name;

    String key;
    if (i == 0 || name.toLowerCase().contains('branch a')) {
      key = 'branch_a';
    } else if (i == 1 || name.toLowerCase().contains('branch b')) {
      key = 'branch_b';
    } else {
      key = id.isNotEmpty ? id : 'branch_${i + 1}';
    }

    updated[key] = label;
    if (id.isNotEmpty) {
      updated[id] = label;
      kBranchUuidToKey[id] = key;
      kBranchKeyToUuid[key] = id;
      kBranchKeyToUuid[id] = id;
    }
  }
  kBranches = updated;
}
