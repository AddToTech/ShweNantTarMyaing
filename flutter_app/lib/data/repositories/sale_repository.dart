// lib/data/repositories/sale_repository.dart

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/drift/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_toast.dart';
import '../../domain/models/sale_transaction.dart';
import '../mock/mock_products.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return SaleRepository(apiClient: apiClient, db: db);
});

class SaleRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;
  final _uuid = const Uuid();

  SaleRepository({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  static PaymentMethodType _parsePaymentMethod(dynamic val) {
    final str = val?.toString().toLowerCase() ?? 'cash';
    if (str.contains('kpay')) return PaymentMethodType.kpay;
    if (str.contains('wave')) return PaymentMethodType.wavePay;
    if (str.contains('bank')) return PaymentMethodType.mobileBanking;
    if (str.contains('credit')) return PaymentMethodType.credit;
    return PaymentMethodType.cash;
  }

  static String _paymentMethodToBackend(PaymentMethodType method) {
    return switch (method) {
      PaymentMethodType.cash => 'cash',
      PaymentMethodType.kpay => 'kpay',
      PaymentMethodType.wavePay => 'banking',
      PaymentMethodType.mobileBanking => 'banking',
      PaymentMethodType.credit => 'credit',
    };
  }

  SaleTransaction _saleFromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List? ?? []).map((it) {
      final itemMap = it as Map<String, dynamic>;
      final rawProdId = itemMap['product_id'] ?? itemMap['productId'];
      final rawProdName = itemMap['product_name'] ?? itemMap['productName'];
      final rawUnitPrice = itemMap['unit_price'] ?? itemMap['unitPrice'];
      final rawDiscount = itemMap['discount_percent'] ?? itemMap['discountPercent'] ?? itemMap['discount_pct'];
      final rawLineTotal = itemMap['line_total'] ?? itemMap['lineTotal'];
      return SaleTransactionItem(
        productId: rawProdId?.toString() ?? '',
        productName: rawProdName?.toString() ?? '',
        quantity: (itemMap['quantity'] is num)
            ? (itemMap['quantity'] as num).toInt()
            : double.tryParse(itemMap['quantity']?.toString() ?? '')?.toInt() ?? 1,
        unitPrice: (rawUnitPrice is num)
            ? rawUnitPrice.toDouble()
            : double.tryParse(rawUnitPrice?.toString() ?? '') ?? 0.0,
        discountPercent: (rawDiscount is num)
            ? rawDiscount.toDouble()
            : double.tryParse(rawDiscount?.toString() ?? '') ?? 0.0,
        lineTotal: (rawLineTotal is num)
            ? rawLineTotal.toDouble()
            : double.tryParse(rawLineTotal?.toString() ?? '') ?? 0.0,
      );
    }).toList();

    final bId = normalizeBranchId(
      (map['branch_id'] ?? map['branchId'])?.toString(),
      branchName: (map['branch_name'] ?? map['branchName'])?.toString(),
    );

    final rawCreatedStr = (map['sold_at'] ?? map['created_at'] ?? map['clientCreatedAt'])?.toString();
    final parsedDate = rawCreatedStr != null ? DateTime.tryParse(rawCreatedStr)?.toLocal() : null;

    final rawDiscountAmt = map['discount_amount'] ?? map['discountAmount'];
    final rawTotalAmt = map['total_amount'] ?? map['totalAmount'];
    final rawTenderedAmt = map['tendered_amount'] ?? map['amount_tendered'] ?? map['tenderedAmount'];
    final rawChangeAmt = map['change_amount'] ?? map['changeAmount'];

    return SaleTransaction(
      receiptNo: (map['receipt_no'] ?? map['receiptNo'] ?? map['saleUuid'])?.toString() ?? '',
      branchId: bId,
      branchName: kBranches[bId] ?? (map['branch_name'] ?? map['branchName'])?.toString() ?? 'SitePyoe Branch',
      cashierName: (map['cashier_name'] ?? map['cashierName'])?.toString() ?? 'Cashier',
      customerName: (map['customer_name'] ?? map['customerName'])?.toString(),
      customerPhone: (map['customer_phone'] ?? map['customerPhone'])?.toString(),
      items: itemsList,
      subtotal: (map['subtotal'] is num) ? (map['subtotal'] as num).toDouble() : double.tryParse(map['subtotal']?.toString() ?? '') ?? 0.0,
      discountAmount: (rawDiscountAmt is num) ? rawDiscountAmt.toDouble() : double.tryParse(rawDiscountAmt?.toString() ?? '') ?? 0.0,
      totalAmount: (rawTotalAmt is num) ? rawTotalAmt.toDouble() : double.tryParse(rawTotalAmt?.toString() ?? '') ?? 0.0,
      paymentMethod: _parsePaymentMethod(map['payment_method'] ?? map['paymentMethod']),
      tenderedAmount: (rawTenderedAmt is num) ? rawTenderedAmt.toDouble() : double.tryParse(rawTenderedAmt?.toString() ?? '') ?? 0.0,
      changeAmount: (rawChangeAmt is num) ? rawChangeAmt.toDouble() : double.tryParse(rawChangeAmt?.toString() ?? '') ?? 0.0,
      notes: map['notes']?.toString(),
      createdAt: parsedDate ?? DateTime.now(),
    );
  }

  /// Submit a sale to the server. If offline or transient error occurs, stores in pendingSales queue.
  Future<SaleTransaction> createSale({
    required String branchId,
    required String branchName,
    String? cashierId,
    String? cashierName,
    String? customerName,
    String? customerPhone,
    required List<SaleTransactionItem> items,
    required double subtotal,
    double discountAmount = 0.0,
    double taxAmount = 0.0,
    required PaymentMethodType paymentMethod,
    double tenderedAmount = 0.0,
    double changeAmount = 0.0,
    String? notes,
  }) async {
    final clientUuid = _uuid.v4();
    final now = DateTime.now();

    final payload = {
      'saleUuid': clientUuid,
      'branchId': resolveBranchUuid(branchId),
      'cashierId': cashierId,
      'cashierName': cashierName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': (subtotal - discountAmount + taxAmount).clamp(0, double.infinity),
      'paymentMethod': _paymentMethodToBackend(paymentMethod),
      'tenderedAmount': tenderedAmount,
      'changeAmount': changeAmount,
      'notes': notes,
      'isOfflineCreated': false,
      'clientCreatedAt': now.toIso8601String(),
      'items': items.map((i) => {
        'productId': i.productId,
        'productName': i.productName,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'discountPercent': i.discountPercent,
        'lineTotal': i.lineTotal,
      }).toList(),
    };

    try {
      final res = await _apiClient.post(
        '/sales',
        body: payload,
        suppressErrorToast: true,
      );
      if (res is Map<String, dynamic>) {
        final serverSale = _saleFromMap(res);
        return serverSale;
      }
    } catch (e) {
      // Offline fallback: Queue into PendingSales for automatic background sync
      debugPrint('[SaleRepository] 📡 Offline: Queuing sale $clientUuid into SQLite pending queue...');
      await _queueOfflineSale(clientUuid, branchId, cashierId ?? 'local_cashier', payload, now);
      AppToast.showInfo('📡 အင်တာနက်မရှိပါ - အရောင်းမှတ်တမ်းကို စက်တွင်း၌ သိမ်းဆည်းပြီးပါပြီ (အင်တာနက်ပြန်ရပါက Server သို့ အလိုအလျောက် ပေးပို့မည်)');
    }

    // Return locally generated sale for instant UI & receipt printing
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final offlineReceiptNo = 'SP-$dateStr-OFF-${clientUuid.substring(0, 4).toUpperCase()}';

    return SaleTransaction(
      receiptNo: offlineReceiptNo,
      branchId: branchId,
      branchName: branchName,
      cashierName: cashierName ?? 'Cashier',
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      totalAmount: (subtotal - discountAmount + taxAmount).clamp(0, double.infinity),
      paymentMethod: paymentMethod,
      tenderedAmount: tenderedAmount,
      changeAmount: changeAmount,
      notes: notes != null ? '$notes (Offline Created)' : '(Offline Created)',
      createdAt: now,
    );
  }

  /// Flushes any locally queued sales to the remote PostgreSQL backend
  Future<void> syncPendingSales() async {
    try {
      final pending = await _db.getUnsyncedSales();
      for (final p in pending) {
        try {
          final map = jsonDecode(p.payloadJson) as Map<String, dynamic>;
          await _apiClient.post('/sales', body: map);
          await _db.markSaleSynced(p.localId);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _queueOfflineSale(
    String uuid,
    String branchId,
    String cashierId,
    Map<String, dynamic> payload,
    DateTime now,
  ) async {
    try {
      await _db.into(_db.pendingSales).insert(
        PendingSalesCompanion.insert(
          saleUuid: uuid,
          branchId: branchId,
          cashierId: cashierId,
          payloadJson: jsonEncode(payload),
          createdAt: now,
        ),
      );

      // Deduct local cache stock
      final items = payload['items'] as List? ?? [];
      for (final item in items) {
        final prodId = item['productId']?.toString();
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
        if (prodId != null && qty > 0) {
          final existing = await (_db.select(_db.branchInventoriesCache)
                ..where((i) => i.branchId.equals(branchId) & i.productId.equals(prodId)))
              .getSingleOrNull();

          if (existing != null) {
            await (_db.update(_db.branchInventoriesCache)
                  ..where((i) => i.id.equals(existing.id)))
                .write(
              BranchInventoriesCacheCompanion(
                stockQuantity: Value((existing.stockQuantity - qty).clamp(0, double.infinity)),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  /// Get sales history (flushes any pending offline sales first)
  Future<List<SaleTransaction>> getSales({
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 100,
  }) async {
    await syncPendingSales();

    final list = <SaleTransaction>[];
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
      };

      final data = await _apiClient.get(
        '/sales',
        queryParams: queryParams,
        suppressErrorToast: true,
      );
      if (data is List) {
        list.addAll(data.map((json) => _saleFromMap(json as Map<String, dynamic>)));
      }
    } catch (_) {}

    try {
      final pending = await _db.getUnsyncedSales();
      for (final p in pending) {
        try {
          final map = jsonDecode(p.payloadJson) as Map<String, dynamic>;
          list.add(_saleFromMap(map));
        } catch (_) {}
      }
    } catch (_) {}

    return list;
  }

  /// Delete/void a sale order from remote database and restore inventory stock
  Future<bool> deleteSale(String receiptNoOrId) async {
    try {
      await _apiClient.delete('/sales/$receiptNoOrId');
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
