// lib/data/repositories/wastage_repository.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/drift/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_toast.dart';
import '../../ui/features/wastage/view_models/wastage_notifier.dart';
import '../mock/mock_products.dart';

final wastageRepositoryProvider = Provider<WastageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return WastageRepository(apiClient: apiClient, db: db);
});

class WastageRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;
  final _uuid = const Uuid();

  WastageRepository({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  static WastageReasonOption _parseReason(dynamic val) {
    final str = val?.toString().toLowerCase() ?? 'other';
    if (str.contains('mortality') || str.contains('dead') || str.contains('withered')) {
      return WastageReasonOption.deadWithered;
    }
    if (str.contains('pest')) return WastageReasonOption.pestInfestation;
    if (str.contains('broken') || str.contains('damage')) return WastageReasonOption.brokenCracked;
    return WastageReasonOption.other;
  }

  static String _reasonToBackend(WastageReasonOption reason) {
    return switch (reason) {
      WastageReasonOption.deadWithered => 'mortality',
      WastageReasonOption.pestInfestation => 'pest_disease',
      WastageReasonOption.brokenCracked => 'broken_pot',
      WastageReasonOption.other => 'other',
    };
  }

  WastageEntry _entryFromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] is num)
        ? (map['quantity'] as num).toDouble()
        : double.tryParse(map['quantity']?.toString() ?? '') ?? 0.0;
    final rawCost = map['unit_cost'] ?? map['unitCost'];
    final cost = (rawCost is num)
        ? rawCost.toDouble()
        : double.tryParse(rawCost?.toString() ?? '') ?? 0.0;
    final rawLoss = map['total_cost_loss'] ?? map['totalCostLoss'];
    final loss = (rawLoss is num) ? rawLoss.toDouble() : qty * cost;

    final bId = normalizeBranchId(
      (map['branch_id'] ?? map['branchId'])?.toString(),
      branchName: (map['branch_name'] ?? map['branchName'])?.toString(),
    );

    final rawDateStr = (map['recorded_at'] ?? map['created_at'] ?? map['createdAt'])?.toString();
    final parsedDate = rawDateStr != null ? DateTime.tryParse(rawDateStr)?.toLocal() : null;

    return WastageEntry(
      id: (map['id'] ?? map['logUuid'])?.toString() ?? '',
      branchId: bId,
      branchName: kBranches[bId] ?? (map['branch_name'] ?? map['branchName'])?.toString() ?? 'SitePyoe Branch',
      productId: (map['product_id'] ?? map['productId'])?.toString() ?? '',
      productName: (map['product_name'] ?? map['productName'])?.toString() ?? '',
      category: ProductCategory.plants,
      quantity: qty.toInt(),
      unitCost: cost,
      totalCostLoss: loss,
      reason: _parseReason(map['reason']),
      notes: map['notes']?.toString() ?? map['description']?.toString(),
      recordedAt: parsedDate ?? DateTime.now(),
    );
  }

  /// Flushes any locally queued wastage logs to the remote PostgreSQL backend
  Future<void> syncPendingWastageLogs() async {
    try {
      final pending = await _db.getUnsyncedWastageLogs();
      for (final p in pending) {
        try {
          final map = jsonDecode(p.payloadJson) as Map<String, dynamic>;
          await _apiClient.post('/wastage', body: map);
          await _db.markWastagelLogSynced(p.localId);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Record a wastage entry
  Future<WastageEntry> recordWastage({
    required String branchId,
    required String branchName,
    required String productId,
    required String productName,
    required double quantity,
    required double unitCost,
    required WastageReasonOption reason,
    String? notes,
  }) async {
    final clientUuid = _uuid.v4();
    final now = DateTime.now();

    final payload = {
      'logUuid': clientUuid,
      'branchId': resolveBranchUuid(branchId),
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'reason': _reasonToBackend(reason),
      'notes': notes,
      'description': notes,
      'createdAt': now.toIso8601String(),
    };

    try {
      final res = await _apiClient.post(
        '/wastage',
        body: payload,
        suppressErrorToast: true,
      );
      if (res is Map<String, dynamic>) {
        return _entryFromMap(res);
      }
    } catch (e) {
      // Queue in Drift pendingWastageLogs for background sync
      try {
        await _db.into(_db.pendingWastageLogs).insert(
          PendingWastageLogsCompanion.insert(
            logUuid: clientUuid,
            branchId: branchId,
            payloadJson: jsonEncode(payload),
            createdAt: now,
          ),
        );
      } catch (_) {}
      AppToast.showInfo('📡 အော့ဖ်လိုင်းစနစ်ဖြင့် အလေအလွင့်စာရင်း မှတ်တမ်းတင်ထားပါသည် (အင်တာနက်ပြန်ရပါက အလိုအလျောက် ပေးပို့မည်)');
    }

    return WastageEntry(
      id: clientUuid,
      branchId: branchId,
      branchName: branchName,
      productId: productId,
      productName: productName,
      category: ProductCategory.plants,
      quantity: quantity.toInt(),
      unitCost: unitCost,
      totalCostLoss: quantity * unitCost,
      reason: reason,
      notes: notes != null ? '$notes (Offline)' : '(Offline)',
      recordedAt: now,
    );
  }

  /// Get wastage logs (flushes any pending offline logs first)
  Future<List<WastageEntry>> getWastageLogs({String? branchId}) async {
    await syncPendingWastageLogs();

    final list = <WastageEntry>[];
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final data = await _apiClient.get('/wastage', queryParams: queryParams);
      if (data is List) {
        list.addAll(data.map((json) => _entryFromMap(json as Map<String, dynamic>)));
      }
    } catch (_) {}

    try {
      final pending = await _db.getUnsyncedWastageLogs();
      for (final p in pending) {
        try {
          final map = jsonDecode(p.payloadJson) as Map<String, dynamic>;
          list.add(_entryFromMap(map));
        } catch (_) {}
      }
    } catch (_) {}

    return list;
  }
}
