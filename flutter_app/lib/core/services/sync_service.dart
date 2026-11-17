// lib/core/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../db/drift/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_toast.dart';

final syncPendingCountProvider = StateProvider<int>((ref) => 0);

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return SyncService(apiClient: apiClient, db: db, ref: ref);
});

class SyncService {
  final ApiClient _apiClient;
  final AppDatabase _db;
  final Ref _ref;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  SyncService({
    required ApiClient apiClient,
    required AppDatabase db,
    required Ref ref,
  })  : _apiClient = apiClient,
        _db = db,
        _ref = ref;

  /// Real ping to check whether internet and backend server are genuinely reachable
  Future<bool> checkInternetReachability({bool showToast = false}) async {
    bool reachable = false;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _ref.read(isOnlineProvider.notifier).state = false;
        if (showToast) {
          AppToast.showError('အင်တာနက် ချိတ်ဆက်မှု မရှိပါ (Device တွင် Wi-Fi သို့မဟုတ် Mobile Data ဖွင့်ထားခြင်း မရှိပါ)');
        }
        return false;
      }

      // Test real HTTP reachability with short timeout (2.5s)
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/health');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 2500));
      reachable = (res.statusCode >= 200 && res.statusCode < 400);
    } catch (_) {
      reachable = false;
    }

    _ref.read(isOnlineProvider.notifier).state = reachable;
    if (showToast) {
      if (reachable) {
        AppToast.showSuccess('Cloud Server နှင့် ချိတ်ဆက်မှု အဆင်ပြေပါသည် (Online)');
      } else {
        AppToast.showError('Wi-Fi ချိတ်ဆက်ထားသော်လည်း အင်တာနက်လိုင်း မရှိပါ (Offline)');
      }
    }
    return reachable;
  }

  /// Start periodic sync and listen for internet reconnection
  void startPeriodicSync({Duration interval = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final online = await checkInternetReachability();
      if (online) {
        syncPendingQueue();
      }
    });

    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasAdapter = !results.contains(ConnectivityResult.none);
      if (!hasAdapter) {
        _ref.read(isOnlineProvider.notifier).state = false;
      } else {
        final isReachable = await checkInternetReachability();
        if (isReachable) {
          debugPrint('[SyncService] 🌐 Internet connectivity confirmed! Triggering instant sync...');
          syncPendingQueue(isAutoOnReconnect: true);
        }
      }
    });

    // Initial check of pending queue count and reachability
    updatePendingCount();
    checkInternetReachability();
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Refreshes the pending sales count in Riverpod
  Future<int> updatePendingCount() async {
    try {
      final sales = await _db.getUnsyncedSales();
      final wastage = await _db.getUnsyncedWastageLogs();
      final count = sales.length + wastage.length;
      _ref.read(syncPendingCountProvider.notifier).state = count;
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Push all queued offline sales and wastage to backend
  Future<bool> syncPendingQueue({bool isAutoOnReconnect = false}) async {
    if (_isSyncing) return false;

    // Check real reachability first
    final isReachable = await checkInternetReachability();
    if (!isReachable) {
      await updatePendingCount();
      return false;
    }

    _isSyncing = true;
    try {
      final unsyncedSales = await _db.getUnsyncedSales();
      final unsyncedWastage = await _db.getUnsyncedWastageLogs();

      if (unsyncedSales.isEmpty && unsyncedWastage.isEmpty) {
        _ref.read(syncPendingCountProvider.notifier).state = 0;
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
        suppressErrorToast: true,
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

        await updatePendingCount();

        if (syncedSales.isNotEmpty || syncedWastage.isNotEmpty) {
          AppToast.showSuccess(
            '📡 အင်တာနက် ပြန်လည်ရရှိပါသဖြင့် အော့ဖ်လိုင်း အရောင်းဘောက်ချာ (${syncedSales.length}) စောင်နှင့် အလေအလွင့် (${syncedWastage.length}) ခုကို Server သို့ အောင်မြင်စွာ Update ပြုလုပ်ပြီးပါပြီ',
          );
        }

        debugPrint('[SyncService] Successfully synced ${syncedSales.length} sales & ${syncedWastage.length} wastage records');
        _isSyncing = false;
        return true;
      }
    } catch (e) {
      debugPrint('[SyncService] Background sync error: $e');
    } finally {
      _isSyncing = false;
      await updatePendingCount();
    }

    return false;
  }
}
