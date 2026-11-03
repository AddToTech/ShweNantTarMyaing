// lib/data/repositories/purchase_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../ui/features/purchases/view_models/purchase_notifier.dart';
import '../mock/mock_products.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PurchaseRepository(apiClient: apiClient);
});

class PurchaseRepository {
  final ApiClient _apiClient;

  PurchaseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static PurchasePaymentStatus _parsePaymentStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? 'unpaid';
    if (str.contains('paid') && !str.contains('un')) return PurchasePaymentStatus.paid;
    if (str.contains('partial')) return PurchasePaymentStatus.partial;
    return PurchasePaymentStatus.unpaid;
  }

  Purchase _purchaseFromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List? ?? []).map((it) {
      final itemMap = it as Map<String, dynamic>;
      final qty = (itemMap['quantity'] is num) ? (itemMap['quantity'] as num).toDouble() : double.tryParse(itemMap['quantity']?.toString() ?? '') ?? 1.0;
      final cost = (itemMap['unit_cost'] is num) ? (itemMap['unit_cost'] as num).toDouble() : double.tryParse(itemMap['unit_cost']?.toString() ?? '') ?? 0.0;

      return PurchaseItem(
        productId: itemMap['product_id']?.toString() ?? '',
        productName: itemMap['product_name_snapshot']?.toString() ?? itemMap['product_name']?.toString() ?? '',
        quantity: qty,
        unitCost: cost,
      );
    }).toList();

    return Purchase(
      id: map['id']?.toString() ?? '',
      purchaseNo: map['purchase_no']?.toString() ?? '',
      branchId: normalizeBranchId(
        map['branch_id']?.toString(),
        branchName: map['branch_name']?.toString(),
      ),
      vendorId: map['vendor_id']?.toString(),
      vendorName: map['vendor_name']?.toString(),
      purchaseDate: map['purchase_date'] != null ? DateTime.tryParse(map['purchase_date'].toString()) ?? DateTime.now() : DateTime.now(),
      items: itemsList,
      discount: (map['discount'] is num) ? (map['discount'] as num).toDouble() : 0.0,
      paidAmount: (map['paid_amount'] is num) ? (map['paid_amount'] as num).toDouble() : 0.0,
      paymentStatus: _parsePaymentStatus(map['payment_status']),
      notes: map['notes']?.toString(),
      createdBy: map['created_by_name']?.toString() ?? map['created_by']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// List purchases
  Future<List<Purchase>> getPurchases({
    String? branchId,
    String? vendorId,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
        if (paymentStatus != null && paymentStatus.isNotEmpty) 'paymentStatus': paymentStatus,
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
      };

      final data = await _apiClient.get('/purchases', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => _purchaseFromMap(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Create purchase order
  Future<Purchase> createPurchase({
    required String branchId,
    String? vendorId,
    DateTime? purchaseDate,
    required List<PurchaseItem> items,
    double discount = 0.0,
    double paidAmount = 0.0,
    String? notes,
    bool autoApplyToInventory = false,
  }) async {
    final payload = {
      'branchId': branchId,
      'vendorId': vendorId,
      'purchaseDate': (purchaseDate ?? DateTime.now()).toIso8601String().split('T').first,
      'discount': discount,
      'paidAmount': paidAmount,
      'notes': notes,
      'autoApplyToInventory': autoApplyToInventory,
      'items': items.map((i) => {
        'productId': i.productId,
        'productName': i.productName,
        'quantity': i.quantity,
        'unitCost': i.unitCost,
      }).toList(),
    };

    final res = await _apiClient.post('/purchases', body: payload);
    return _purchaseFromMap(res as Map<String, dynamic>);
  }

  /// Apply purchase items to inventory
  Future<void> confirmPurchase(String id) async {
    await _apiClient.post('/purchases/$id/confirm');
  }

  /// Record payment against purchase balance
  Future<void> recordPayment(String id, double paymentAmount) async {
    await _apiClient.patch('/purchases/$id/pay', body: {'paymentAmount': paymentAmount});
  }
}

