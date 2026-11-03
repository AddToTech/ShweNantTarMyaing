// lib/domain/models/product.dart
// ============================================================
// Clean Domain Models — immutable data classes
// These are what ViewModels and Use Cases work with.
// No dependency on drift, json_serializable, or network.
// ============================================================

enum OriginType { thaiImport, chinaImport, local }
enum WastageReason { mortality, pestDisease, weatherDamage, physicalDamage, theft, expiry, qualityReject, other }
enum PaymentMethod { cash, kpay, banking, credit }
enum SaleStatus { completed, voided, refunded }
enum TransferStatus { pending, inTransit, received, cancelled }
enum UserRole { owner, manager, cashier, stockClerk }

// ── Branch ──────────────────────────────────────────────────
class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.isActive,
  });
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'isActive': isActive,
  };
}

// ── Category ────────────────────────────────────────────────
class Category {
  const Category({required this.id, required this.name, required this.sortOrder, required this.subcategories});
  final String id;
  final String name;
  final int sortOrder;
  final List<Subcategory> subcategories;
}

class Subcategory {
  const Subcategory({required this.id, required this.categoryId, required this.name, required this.sortOrder});
  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;
}

// ── Product ─────────────────────────────────────────────────
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.name,
    this.sku,
    this.barcode,
    required this.costPrice,
    required this.salePrice,
    this.originType,       // Plants only
    this.sizeLabel,        // Plants only
    this.expiryDate,       // Chemicals only
    required this.unitOfMeasure,
    required this.attributes,
    required this.isActive,
  });

  final String id;
  final String categoryId;
  final String? subcategoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double salePrice;
  final OriginType? originType;
  final String? sizeLabel;
  final DateTime? expiryDate;
  final String unitOfMeasure;
  final Map<String, dynamic> attributes;
  final bool isActive;

  String get imageEmoji => attributes['imageEmoji'] as String? ?? '🌿';
  String? get customImagePath => attributes['customImagePath'] as String?;
}

// ── Branch Inventory ─────────────────────────────────────────
class BranchInventory {
  const BranchInventory({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.product,
    required this.stockQuantity,
    required this.minAlertThreshold,
  });
  final String id;
  final String branchId;
  final String productId;
  final Product product;
  final double stockQuantity;
  final double minAlertThreshold;

  bool get isLowStock => stockQuantity <= minAlertThreshold;
}

// ── Sale ────────────────────────────────────────────────────
class Sale {
  const Sale({
    required this.id,
    required this.branchId,
    this.cashierId,
    required this.receiptNo,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    this.amountTendered,
    this.changeAmount,
    this.customerName,
    this.customerPhone,
    required this.isDebtCleared,
    required this.status,
    required this.soldAt,
  });

  final String id;
  final String branchId;
  final String? cashierId;
  final String receiptNo;
  final List<SaleItem> items;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double? amountTendered;
  final double? changeAmount;
  final String? customerName;
  final String? customerPhone;
  final bool isDebtCleared;
  final SaleStatus status;
  final DateTime soldAt;
}

class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.discountPct,
    required this.lineTotal,
  });
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double discountPct;
  final double lineTotal;
}

// ── Branch Transfer ──────────────────────────────────────────
class BranchTransfer {
  const BranchTransfer({
    required this.id,
    required this.fromBranchId,
    required this.toBranchId,
    required this.referenceNo,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
  });
  final String id;
  final String fromBranchId;
  final String toBranchId;
  final String referenceNo;
  final TransferStatus status;
  final List<TransferItem> items;
  final String? notes;
  final DateTime createdAt;
}

class TransferItem {
  const TransferItem({
    required this.id,
    required this.transferId,
    required this.productId,
    required this.productName,
    required this.requestedQuantity,
    this.receivedQuantity,
    required this.unitCost,
  });
  final String id;
  final String transferId;
  final String productId;
  final String productName;
  final double requestedQuantity;
  final double? receivedQuantity;
  final double unitCost;
}

// ── Wastage Log ──────────────────────────────────────────────
class WastageLog {
  const WastageLog({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.reason,
    this.description,
    this.photoUrl,
    required this.recordedAt,
  });
  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final WastageReason reason;
  final String? description;
  final String? photoUrl;
  final DateTime recordedAt;

  double get totalCostLoss => quantity * unitCost;
}
