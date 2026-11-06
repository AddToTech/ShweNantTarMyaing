// ============================================================
// PlantOriginNotifier — State management for dynamic plant origins
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/plant_origin_repository.dart';
import '../../../../domain/models/plant_origin.dart';

final plantOriginLoadingProvider = StateProvider<bool>((ref) => false);

class PlantOriginNotifier extends Notifier<List<PlantOrigin>> {
  @override
  List<PlantOrigin> build() {
    _loadFromRemote();
    return PlantOriginRepository.kDefaultOrigins;
  }

  Future<void> loadOrigins() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    ref.read(plantOriginLoadingProvider.notifier).state = true;
    try {
      final remote = await ref.read(plantOriginRepositoryProvider).getOrigins();
      if (remote.isNotEmpty) {
        state = remote;
      }
    } catch (_) {
    } finally {
      ref.read(plantOriginLoadingProvider.notifier).state = false;
    }
  }

  Future<PlantOrigin?> addOrigin({
    required String name,
    String? code,
    int sortOrder = 0,
  }) async {
    try {
      final created = await ref.read(plantOriginRepositoryProvider).createOrigin(
            name: name,
            code: code,
            sortOrder: sortOrder,
          );
      state = [...state.where((o) => o.id != created.id), created];
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateOrigin(
    String id, {
    String? name,
    String? code,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updated = await ref.read(plantOriginRepositoryProvider).updateOrigin(
            id,
            name: name,
            code: code,
            sortOrder: sortOrder,
            isActive: isActive,
          );
      state = state.map((o) => o.id == id ? updated : o).toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteOrigin(String id) async {
    try {
      final ok = await ref.read(plantOriginRepositoryProvider).deleteOrigin(id);
      if (ok) {
        state = state.where((o) => o.id != id).toList();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}

final plantOriginProvider =
    NotifierProvider<PlantOriginNotifier, List<PlantOrigin>>(PlantOriginNotifier.new);

/// Active plant origins sorted by sortOrder
final activePlantOriginsProvider = Provider<List<PlantOrigin>>((ref) {
  final origins = ref.watch(plantOriginProvider);
  final active = origins.where((o) => o.isActive).toList();
  active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return active;
});
