import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/app_permission.dart';

// ============================================================
// PermissionGroupNotifier
// Manages CRUD for Left Side Menu Permission Groups via Backend API
// ============================================================

final permissionGroupLoadingProvider = StateProvider<bool>((ref) => true);

class PermissionGroupNotifier extends Notifier<List<PermissionGroup>> {
  @override
  List<PermissionGroup> build() {
    loadGroups();
    return const [];
  }

  /// Load permission groups from remote PostgreSQL backend
  Future<void> loadGroups() async {
    ref.read(permissionGroupLoadingProvider.notifier).state = true;
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/permission-groups');
      if (data is List) {
        state = data
            .map((e) => PermissionGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      ref.read(permissionGroupLoadingProvider.notifier).state = false;
    }
  }

  /// Create a new custom permission group
  Future<bool> addGroup({
    required String name,
    required String burmeseName,
    required String description,
    required String icon,
    required List<AppMenuPermission> permissions,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final newId = 'pg_${DateTime.now().millisecondsSinceEpoch}';
      await client.post('/permission-groups', body: {
        'id': newId,
        'name': name.trim(),
        'burmeseName': burmeseName.trim(),
        'description': description.trim(),
        'icon': icon.trim().isEmpty ? '🛡️' : icon.trim(),
        'permissions': permissions.map((p) => p.code).toList(),
      });
      await loadGroups();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update an existing permission group
  Future<bool> updateGroup({
    required String id,
    required String name,
    required String burmeseName,
    required String description,
    required String icon,
    required List<AppMenuPermission> permissions,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/permission-groups/$id', body: {
        'name': name.trim(),
        'burmeseName': burmeseName.trim(),
        'description': description.trim(),
        'icon': icon.trim().isEmpty ? '🛡️' : icon.trim(),
        'permissions': permissions.map((p) => p.code).toList(),
      });
      await loadGroups();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a permission group (only non-builtin groups can be deleted)
  Future<String?> deleteGroup(String id) async {
    final target = state.where((g) => g.id == id).firstOrNull;
    if (target != null && target.isBuiltIn) {
      return 'စနစ်၏ မူလသတ်မှတ်ထားသော Permission Group (${target.name}) ကို ဖျက်၍မရပါ';
    }
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/permission-groups/$id');
      state = state.where((g) => g.id != id).toList();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('ApiException: ', '');
    }
  }

  /// Reset all groups to default preset in backend
  Future<bool> resetToDefaults() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.post('/permission-groups/reset');
      if (data is List) {
        state = data
            .map((e) => PermissionGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        await loadGroups();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final permissionGroupProvider =
    NotifierProvider<PermissionGroupNotifier, List<PermissionGroup>>(
  PermissionGroupNotifier.new,
);
