// ============================================================
// PlantOrigin domain model (Dynamic plant origins from backend)
// ============================================================

class PlantOrigin {
  const PlantOrigin({
    required this.id,
    required this.name,
    this.code,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String? code;
  final int sortOrder;
  final bool isActive;
  final int productCount;

  factory PlantOrigin.fromJson(Map<String, dynamic> json) {
    return PlantOrigin(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      sortOrder: (json['sort_order'] is num) ? (json['sort_order'] as num).toInt() : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] != false,
      productCount: (json['product_count'] is num) ? (json['product_count'] as num).toInt() : int.tryParse(json['product_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'sort_order': sortOrder,
    'is_active': isActive,
    'product_count': productCount,
  };

  PlantOrigin copyWith({
    String? name,
    String? code,
    int? sortOrder,
    bool? isActive,
    int? productCount,
  }) {
    return PlantOrigin(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantOrigin && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
