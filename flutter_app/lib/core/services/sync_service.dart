// lib/core/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/drift/app_database.dart';
import '../network/api_client.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return SyncService(apiClient: apiClient, db: db);
});

class SyncService {
  final ApiClient _apiClient;
  final AppDatabase _db;
  Timer? _timer;
  bool _isSyncing = false;

  SyncService({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  /// Start periodic sync (every 5 minutes)
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncPendingQueue());
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Push all queued offline sales and wastage to backend
  Future<bool> syncPendingQueue() async {
    if (_isSyncing) return false;

    // Check connectivity first
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
    } catch (_) {}

    _isSyncing = true;
    try {
      final unsyncedSales = await _db.getUnsyncedSales();
      final unsyncedWastage = await _db.getUnsyncedWastageLogs();

      if (unsyncedSales.isEmpty && unsyncedWastage.isEmpty) {
        _isSyncing = false;
        return true;
      }

      final branchId = unsyncedSales.isNotEmpty
          ? unsyncedSales.first.branchId
          : (unsyncedWastage.isNotEmpty ? unsyncedWastage.first.branchId : 'branch_a');

      final salesPayload = <Map<String, dynamic>>[];
      for (final s in unsyncedSales) {
        try {
          final map = jsonDecode(s.payloadJson) as Map<String, dynamic>;
          salesPayload.add(map);
        } catch (_) {}
      }

      final wastagePayload = <Map<String, dynamic>>[];
      for (final w in unsyncedWastage) {
        try {
          final map = jsonDecode(w.payloadJson) as Map<String, dynamic>;
          wastagePayload.add(map);
        } catch (_) {}
      }

      final response = await _apiClient.post(
        '/sync/push',
        body: {
          'branchId': branchId,
          'sales': salesPayload,
          'wastageLogs': wastagePayload,
        },
      );

      if (response is Map<String, dynamic>) {
        final syncedSales = (response['syncedSaleUuids'] as List? ?? []).map((e) => e.toString()).toSet();
        final syncedWastage = (response['syncedWastageUuids'] as List? ?? []).map((e) => e.toString()).toSet();

        for (final s in unsyncedSales) {
          if (syncedSales.contains(s.saleUuid)) {
            await _db.markSaleSynced(s.localId);
          }
        }

        for (final w in unsyncedWastage) {
          if (syncedWastage.contains(w.logUuid)) {
            await _db.markWastagelLogSynced(w.localId);
          }
        }

        debugPrint('[SyncService] Successfully synced ${syncedSales.length} sales & ${syncedWastage.length} wastage records');
        _isSyncing = false;
        return true;
      }
    } catch (e) {
      debugPrint('[SyncService] Background sync error: $e');
    } finally {
      _isSyncing = false;
    }

    return false;
  }
}
