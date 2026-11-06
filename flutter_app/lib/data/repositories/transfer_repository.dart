// lib/data/repositories/transfer_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../ui/features/branch_transfer/view_models/transfer_notifier.dart';
import '../mock/mock_products.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransferRepository(apiClient: apiClient);
});

class TransferRepository {
  final ApiClient _apiClient;

  TransferRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static TransferVoucherStatus _parseStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? 'in_transit';
    if (str.contains('receive')) return TransferVoucherStatus.received;
    if (str.contains('cancel')) return TransferVoucherStatus.cancelled;
    return TransferVoucherStatus.inTransit;
  }

  TransferVoucher _voucherFromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List? ?? []).map((it) {
      final itemMap = it as Map<String, dynamic>;
      final qty = (itemMap['sent_quantity'] is num)
          ? (itemMap['sent_quantity'] as num).toInt()
          : ((itemMap['quantity'] is num) ? (itemMap['quantity'] as num).toInt() : 1);
      final cost = (itemMap['unit_cost'] is num) ? (itemMap['unit_cost'] as num).toDouble() : 0.0;

      return TransferItemRecord(
        productId: itemMap['product_id']?.toString() ?? '',
        productName: itemMap['product_name']?.toString() ?? '',
        quantity: qty,
        unitCost: cost,
        category: ProductCategory.plants,
      );
    }).toList();

    final fromBId = normalizeBranchId(
      map['from_branch_id']?.toString(),
      branchName: map['from_branch_name']?.toString(),
    );
    final toBId = normalizeBranchId(
      map['to_branch_id']?.toString(),
      branchName: map['to_branch_name']?.toString(),
    );
    return TransferVoucher(
      id: map['id']?.toString() ?? map['transfer_no']?.toString() ?? map['reference_no']?.toString() ?? '',
      fromBranchId: fromBId,
      fromBranchName: kBranches[fromBId] ?? map['from_branch_name']?.toString() ?? 'SitePyoe Main',
      toBranchId: toBId,
      toBranchName: kBranches[toBId] ?? map['to_branch_name']?.toString() ?? 'SitePyoe Branch',
      items: itemsList,
      status: _parseStatus(map['status']),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      receivedAt: map['received_at'] != null ? DateTime.tryParse(map['received_at'].toString()) : null,
    );
  }

  /// Get transfer history
  Future<List<TransferVoucher>> getTransfers({String? branchId}) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final data = await _apiClient.get('/transfers', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => _voucherFromMap(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Create inter-branch transfer
  Future<TransferVoucher> createTransfer({
    required String fromBranchId,
    required String toBranchId,
    required List<TransferItemRecord> items,
    String? notes,
  }) async {
    final payload = {
      'fromBranchId': resolveBranchUuid(fromBranchId),
      'toBranchId': resolveBranchUuid(toBranchId),
      'notes': notes,
      'items': items.map((i) => {
        'productId': i.productId,
        'sentQuantity': i.quantity,
      }).toList(),
    };

    final res = await _apiClient.post('/transfers', body: payload);
    return _voucherFromMap(res as Map<String, dynamic>);
  }

  /// Confirm received transfer
  Future<void> receiveTransfer(String transferId) async {
    await _apiClient.patch('/transfers/$transferId/receive', body: {'items': []});
  }
}
