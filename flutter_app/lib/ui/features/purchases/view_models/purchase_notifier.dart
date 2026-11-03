// ============================================================
// Purchase domain model & Riverpod PurchaseNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/mock/mock_purchases.dart';
import '../../../../data/repositories/purchase_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';

// ── Payment status enum ───────────────────────────────────────
enum PurchasePaymentStatus {
  paid,
  unpaid,
  partial;

  String get burmeseLabel => switch (this) {
    paid    => 'ငွေကြေ (Paid)',
    unpaid  => 'အကြွေး (Credit)',
    partial => 'တစ်စိတ်ပေး (Partial)',
  };

  String get shortLabel => switch (this) {
    paid    => 'ငွေကြေ',
    unpaid  => 'အကြွေး',
    partial => 'တစ်စိတ်',
  };

  String get code => name;
}

// ── Purchase Item ─────────────────────────────────────────────
class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;

  double get totalCost => quantity * unitCost;

  PurchaseItem copyWith({double? quantity, double? unitCost}) {
    return PurchaseItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

// ── Purchase (invoice header) ─────────────────────────────────
class Purchase {
  const Purchase({
    required this.id,
    required this.purchaseNo,
    required this.branchId,
    this.vendorId,
    this.vendorName,
    required this.purchaseDate,
    required this.items,
    this.discount = 0,
    required this.paidAmount,
    required this.paymentStatus,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String purchaseNo;
  final String branchId;
  final String? vendorId;
  final String? vendorName;
  final DateTime purchaseDate;
  final List<PurchaseItem> items;
  final double discount;
  final double paidAmount;
  final PurchasePaymentStatus paymentStatus;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  double get subtotal    => items.fold(0, (s, i) => s + i.totalCost);
  double get totalAmount => (subtotal - discount).clamp(0, double.infinity);
  double get balanceDue  => (totalAmount - paidAmount).clamp(0, double.infinity);

  Purchase copyWith({
    double? paidAmount,
    PurchasePaymentStatus? paymentStatus,
    String? notes,
  }) {
    return Purchase(
      id: id,
      purchaseNo: purchaseNo,
      branchId: branchId,
      vendorId: vendorId,
      vendorName: vendorName,
      purchaseDate: purchaseDate,
      items: items,
      discount: discount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  String get branchLabel => kBranches[branchId] ?? (branchId == 'branch_a'
      ? 'ရန်ကုန် ပင်မဆိုင်ခွဲ'
      : (branchId == 'branch_b' ? 'မန္တလေး ဆိုင်ခွဲ' : branchId));
}

// ── PurchaseNotifier state ────────────────────────────────────
class PurchaseState {
  const PurchaseState({
    this.purchases = const [],
    this.isLoading = true,
  });

  final List<Purchase> purchases;
  final bool isLoading;

  PurchaseState copyWith({
    List<Purchase>? purchases,
    bool? isLoading,
  }) =>
      PurchaseState(
        purchases: purchases ?? this.purchases,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── PurchaseNotifier ──────────────────────────────────────────
class PurchaseNotifier extends Notifier<PurchaseState> {
  @override
  PurchaseState build() {
    _loadFromRemote();
    return const PurchaseState(isLoading: true);
  }

  Future<void> loadPurchases() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    state = state.copyWith(isLoading: true);
    try {
      final remote = await ref.read(purchaseRepositoryProvider).getPurchases();
      state = state.copyWith(purchases: remote, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Submit a completed purchase invoice.
  /// Returns true only if the backend API request succeeds.
  Future<bool> submitPurchase({
    required String branchId,
    String? vendorId,
    String? vendorName,
    required DateTime purchaseDate,
    required List<PurchaseItem> items,
    required double discount,
    required double paidAmount,
    required PurchasePaymentStatus paymentStatus,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final created = await ref.read(purchaseRepositoryProvider).createPurchase(
        branchId: branchId,
        vendorId: vendorId,
        purchaseDate: purchaseDate,
        items: items,
        discount: discount,
        paidAmount: paidAmount,
        notes: notes,
        autoApplyToInventory: true,
      );

      state = state.copyWith(
        purchases: [created, ...state.purchases],
      );

      // Increment branch inventory for each item
      final invNotifier = ref.read(inventoryProvider.notifier);
      for (final item in items) {
        invNotifier.addStock(branchId, item.productId, item.quantity.toInt());
      }

      // Reload catalog to reflect updated cost prices from server
      await ref.read(catalogProvider.notifier).loadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Record a payment towards an outstanding purchase invoice.
  /// Returns true only if the backend API request succeeds.
  Future<bool> recordPayment({
    required String purchaseId,
    required double paymentAmount,
    String? note,
  }) async {
    try {
      await ref.read(purchaseRepositoryProvider).recordPayment(purchaseId, paymentAmount);

      final existingInState = state.purchases.any((p) => p.id == purchaseId);
      final allList = existingInState
          ? state.purchases
          : [...state.purchases, ...kBaselinePurchases];

      state = state.copyWith(
        purchases: allList.map((p) {
          if (p.id != purchaseId) return p;

          final newPaid = (p.paidAmount + paymentAmount).clamp(0.0, p.totalAmount);
          final newStatus = newPaid >= p.totalAmount
              ? PurchasePaymentStatus.paid
              : (newPaid > 0 ? PurchasePaymentStatus.partial : PurchasePaymentStatus.unpaid);

          final paymentNote = note != null && note.trim().isNotEmpty ? note.trim() : null;
          final updatedNotes = paymentNote != null
              ? (p.notes != null ? '${p.notes}\n[ငွေချေ]: $paymentNote' : '[ငွေချေ]: $paymentNote')
              : p.notes;

          return p.copyWith(
            paidAmount: newPaid,
            paymentStatus: newStatus,
            notes: updatedNotes,
          );
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Purchase> getPurchasesByBranch(String branchId) =>
      state.purchases.where((p) => p.branchId == branchId).toList();

  List<Purchase> getPurchasesByVendor(String vendorId) =>
      state.purchases.where((p) => p.vendorId == vendorId).toList();
}

final purchaseProvider =
    NotifierProvider<PurchaseNotifier, PurchaseState>(PurchaseNotifier.new);

/// Outstanding payables per vendor (unpaid + partial purchases)
final vendorPayablesProvider = Provider.family<double, String>((ref, vendorId) {
  final purchases = ref.watch(purchaseProvider).purchases;
  return purchases
      .where((p) =>
          p.vendorId == vendorId &&
          p.paymentStatus != PurchasePaymentStatus.paid)
      .fold(0.0, (sum, p) => sum + p.balanceDue);
});
