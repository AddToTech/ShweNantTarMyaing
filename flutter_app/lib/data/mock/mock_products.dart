// ============================================================
// Product model & catalog (synced with PostgreSQL backend)
// ============================================================

import 'dart:collection';
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
    this.originId,
    this.originName,
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
  final String? originId;
  final String? originName;
  final String? sizeLabel;

  /// Returns the displayable origin label (dynamic name or legacy enum label)
  String? get displayOrigin {
    if (originName != null && originName!.trim().isNotEmpty) return originName!.trim();
    if (originType != null) return originType!.burmeseLabel;
    return null;
  }
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

  /// Checks whether this product matches a comprehensive search query:
  /// item name, category name, vendor name, plant origin, subcategory, SKU, or barcode.
  bool matchesSearch(
    String query, {
    Map<String, String>? categoryNames,
    Map<String, String>? vendorNames,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    // 1. Item Name
    if (name.toLowerCase().contains(q)) return true;

    // 2. SKU & Barcode
    if (sku.toLowerCase().contains(q)) return true;
    if (barcode != null && barcode!.toLowerCase().contains(q)) return true;

    // 3. Category Name (stored or resolved)
    if (categoryName != null && categoryName!.toLowerCase().contains(q)) return true;
    if (category.name.toLowerCase().contains(q)) return true;
    if (category == ProductCategory.plants && (q.contains('အပင်') || 'အပင်'.contains(q) || q.contains('plant') || 'plants'.contains(q))) return true;
    if (category == ProductCategory.pots && (q.contains('ပန်းအိုး') || q.contains('အိုး') || 'ပန်းအိုး'.contains(q) || q.contains('pot') || 'pots'.contains(q))) return true;
    if (category == ProductCategory.chemicals && (q.contains('ဆေး') || q.contains('မြေသြဇာ') || 'ဆေး'.contains(q) || q.contains('chem') || 'chemicals'.contains(q))) return true;
    if (category == ProductCategory.tools && (q.contains('ကိရိယာ') || 'ကိရိယာ'.contains(q) || q.contains('tool') || 'tools'.contains(q))) return true;
    if (category == ProductCategory.others && (q.contains('အထွေထွေ') || 'အထွေထွေ'.contains(q) || q.contains('other') || 'others'.contains(q))) return true;
    if (categoryId != null && categoryNames != null && categoryNames[categoryId]?.toLowerCase().contains(q) == true) {
      return true;
    }

    // 4. Subcategory Name
    if (subcategory.isNotEmpty && subcategory.toLowerCase().contains(q)) return true;

    // 5. Vendor Name (stored or resolved)
    if (vendorName != null && vendorName!.toLowerCase().contains(q)) return true;
    if (vendorId != null && vendorNames != null && vendorNames[vendorId]?.toLowerCase().contains(q) == true) {
      return true;
    }

    // 6. Plant Origin (burmese, short label, english name, dynamic origin name)
    if (originName != null && originName!.toLowerCase().contains(q)) return true;
    if (originType != null) {
      if (originType!.burmeseLabel.toLowerCase().contains(q)) return true;
      if (originType!.shortLabel.toLowerCase().contains(q)) return true;
      final originStr = originType!.name.toLowerCase();
      if (originStr.contains(q)) return true;
      if (originType == OriginType.thaiImport &&
          (q.contains('thai') || q.contains('ယိုးဒယား') || 'thai'.contains(q) || 'ယိုးဒယား'.contains(q))) {
        return true;
      }
      if (originType == OriginType.chinaImport &&
          (q.contains('china') || q.contains('တရုတ်') || 'china'.contains(q) || 'တရုတ်'.contains(q))) {
        return true;
      }
      if (originType == OriginType.local &&
          (q.contains('local') || q.contains('ပြည်တွင်း') || 'local'.contains(q) || 'ပြည်တွင်း'.contains(q))) {
        return true;
      }
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
    String? originId,
    String? originName,
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
      originId: originId ?? this.originId,
      originName: originName ?? this.originName,
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
    final rawOriginId = (json['origin_id'] ?? json['originId'])?.toString();
    final rawOriginName = (json['origin_name'] ?? json['originName'])?.toString() ??
        (json['origin_type'] != null && origStr.isNotEmpty && origin == null ? json['origin_type'].toString() : null);

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
      originId: rawOriginId,
      originName: rawOriginName ?? origin?.burmeseLabel,
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
    'originType': originName ?? originType?.name,
    'originId': originId,
    'originName': originName,
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

/// A customized Map that stores each unique branch exactly once (avoiding duplicate dropdown items),
/// while seamlessly resolving lookups by canonical branch key ('branch_a') or backend UUID.
class BranchLookupMap extends MapBase<String, String> {
  final Map<String, String> _internal = {};

  BranchLookupMap([Map<String, String>? initial]) {
    if (initial != null) _internal.addAll(initial);
  }

  @override
  String? operator [](Object? key) {
    if (key == null) return null;
    final direct = _internal[key];
    if (direct != null) return direct;
    final mappedKey = kBranchUuidToKey[key];
    if (mappedKey != null && _internal.containsKey(mappedKey)) {
      return _internal[mappedKey];
    }
    final mappedUuid = kBranchKeyToUuid[key];
    if (mappedUuid != null && _internal.containsKey(mappedUuid)) {
      return _internal[mappedUuid];
    }
    return null;
  }

  @override
  void operator []=(String key, String value) {
    _internal[key] = value;
  }

  @override
  void clear() => _internal.clear();

  @override
  Iterable<String> get keys => _internal.keys;

  @override
  String? remove(Object? key) => _internal.remove(key);

  @override
  bool containsKey(Object? key) {
    if (key == null) return false;
    if (_internal.containsKey(key)) return true;
    final mappedKey = kBranchUuidToKey[key];
    if (mappedKey != null && _internal.containsKey(mappedKey)) return true;
    final mappedUuid = kBranchKeyToUuid[key];
    if (mappedUuid != null && _internal.containsKey(mappedUuid)) return true;
    return false;
  }
}

Map<String, String> kBranches = BranchLookupMap({
  'branch_a': 'SitePyoe Branch A',
  'branch_b': 'SitePyoe Branch B',
});

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
  if (kBranchUuidToKey.containsKey(rawId)) return kBranchUuidToKey[rawId]!;
  if (kBranches.containsKey(rawId)) return rawId;

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
  kBranchUuidToKey.clear();
  kBranchKeyToUuid.clear();

  // Filter for active branches if is_active is present
  final activeList = rawBranches.where((r) => r['is_active'] != false && r['isActive'] != false).toList();
  final listToUse = activeList.isNotEmpty ? activeList : rawBranches;

  for (var i = 0; i < listToUse.length; i++) {
    final row = listToUse[i];
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

    // Only add ONE canonical key per branch into updated map so dropdowns will never duplicate!
    updated[key] = label;
    if (id.isNotEmpty) {
      kBranchUuidToKey[id] = key;
      kBranchKeyToUuid[key] = id;
    }
  }
  kBranches = BranchLookupMap(updated);
}
