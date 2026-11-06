// lib/data/repositories/branch_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/db/drift/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_toast.dart';
import '../../domain/models/product.dart';
import '../mock/mock_products.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return BranchRepository(apiClient: apiClient, db: db);
});

class BranchesNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    Future.microtask(() => loadBranches());
    return Map<String, String>.from(kBranches);
  }

  void syncFromList(List<Branch> list) {
    state = Map<String, String>.from(kBranches);
  }

  Future<void> loadBranches() async {
    try {
      final repo = ref.read(branchRepositoryProvider);
      await repo.getBranches();
      state = Map<String, String>.from(kBranches);
    } catch (_) {}
  }
}

final branchesProvider = NotifierProvider<BranchesNotifier, Map<String, String>>(
  BranchesNotifier.new,
);

const String kPrefDefaultBranchId = 'sitepyoe_default_branch_id';

class DefaultBranchNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromPrefs();
    return 'branch_a';
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kPrefDefaultBranchId);
      if (saved != null && saved.isNotEmpty) {
        state = normalizeBranchId(saved);
      }
    } catch (_) {}
  }

  Future<void> setDefaultBranch(String branchId) async {
    final normalized = normalizeBranchId(branchId);
    state = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefDefaultBranchId, normalized);
    } catch (_) {}
  }
}

final defaultBranchProvider = NotifierProvider<DefaultBranchNotifier, String>(
  DefaultBranchNotifier.new,
);

final branchLoadingProvider = StateProvider<bool>((ref) => true);

class BranchListNotifier extends Notifier<List<Branch>> {
  @override
  List<Branch> build() {
    Future.microtask(() => loadBranches());
    return const [];
  }

  Future<void> loadBranches() async {
    ref.read(branchLoadingProvider.notifier).state = true;
    try {
      final repo = ref.read(branchRepositoryProvider);
      final list = await repo.getBranches(includeInactive: true);
      state = list;
      ref.read(branchesProvider.notifier).syncFromList(list);
    } catch (_) {
    } finally {
      ref.read(branchLoadingProvider.notifier).state = false;
    }
  }

  Future<Branch?> addBranch({
    required String name,
    String? address,
    String? phone,
    bool isActive = true,
  }) async {
    try {
      final repo = ref.read(branchRepositoryProvider);
      final created = await repo.createBranch(
        name: name,
        address: address,
        phone: phone,
        isActive: isActive,
      );
      state = [...state, created];
      await loadBranches();
      AppToast.showSuccess('ဆိုင်ခွဲ "${created.name}" အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ');
      return created;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final repo = ref.read(branchRepositoryProvider);
      final updated = await repo.updateBranch(
        id,
        name: name,
        address: address,
        phone: phone,
        isActive: isActive,
      );
      state = [
        for (final b in state)
          if (b.id == id) updated else b,
      ];
      await loadBranches();
      AppToast.showSuccess('ဆိုင်ခွဲ "${updated.name}" အချက်အလက်များ မွမ်းမံပြီးပါပြီ');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBranch(String id) async {
    try {
      final repo = ref.read(branchRepositoryProvider);
      final result = await repo.deleteBranch(id);
      await loadBranches();
      final msg = result['message']?.toString() ?? 'ဆောင်ရွက်ပြီးပါပြီ';
      AppToast.showSuccess(msg);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final branchListNotifierProvider =
    NotifierProvider<BranchListNotifier, List<Branch>>(
  BranchListNotifier.new,
);

class BranchRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;

  BranchRepository({
    required ApiClient apiClient,
    required AppDatabase db,
  })  : _apiClient = apiClient,
        _db = db;

  /// Fetch all branches from backend, fallback to local cache
  Future<List<Branch>> getBranches({bool includeInactive = true}) async {
    try {
      final data = await _apiClient.get(
        '/branches',
        queryParams: {'includeInactive': includeInactive ? 'true' : 'false'},
      );
      if (data is List) {
        final rawMaps = data.whereType<Map<String, dynamic>>().toList();
        updateDynamicBranchesFromApi(rawMaps);

        final branches = rawMaps.map((map) {
          return Branch.fromJson(map);
        }).toList();

        // Update local cache
        try {
          final companions = branches.map((b) => BranchesCacheCompanion.insert(
            id: b.id,
            name: b.name,
            address: Value(b.address),
            isActive: Value(b.isActive),
            updatedAt: DateTime.now(),
          )).toList();
          await _db.batch((batch) {
            batch.insertAllOnConflictUpdate(_db.branchesCache, companions);
          });
        } catch (_) {}

        return branches;
      }
    } catch (_) {
      // Offline fallback
      final cached = await _db.select(_db.branchesCache).get();
      if (cached.isNotEmpty) {
        updateDynamicBranchesFromApi(cached.map((c) => {
          'id': c.id,
          'name': c.name,
          'address': c.address,
          'is_active': c.isActive,
        }).toList());
        return cached.map((c) => Branch(
          id: c.id,
          name: c.name,
          address: c.address,
          isActive: c.isActive,
        )).toList();
      }
    }

    return const [];
  }

  /// Create new branch
  Future<Branch> createBranch({
    required String name,
    String? address,
    String? phone,
    bool isActive = true,
  }) async {
    final res = await _apiClient.post('/branches', body: {
      'name': name.trim(),
      'address': address?.trim(),
      'phone': phone?.trim(),
      'isActive': isActive,
    });
    if (res is Map<String, dynamic>) {
      return Branch.fromJson(res);
    }
    throw Exception('Failed to create branch');
  }

  /// Update branch
  Future<Branch> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    final res = await _apiClient.patch('/branches/$id', body: {
      if (name != null) 'name': name.trim(),
      if (address != null) 'address': address.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (isActive != null) 'isActive': isActive,
    });
    if (res is Map<String, dynamic>) {
      return Branch.fromJson(res);
    }
    throw Exception('Failed to update branch');
  }

  /// Delete or deactivate branch
  Future<Map<String, dynamic>> deleteBranch(String id) async {
    final res = await _apiClient.delete('/branches/$id');
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'success': true};
  }
}
