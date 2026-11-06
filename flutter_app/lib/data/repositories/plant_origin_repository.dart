// lib/data/repositories/plant_origin_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/plant_origin.dart';

final plantOriginRepositoryProvider = Provider<PlantOriginRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlantOriginRepository(apiClient: apiClient);
});

class PlantOriginRepository {
  final ApiClient _apiClient;

  PlantOriginRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Default fallback seeds if network is offline
  static const List<PlantOrigin> kDefaultOrigins = [
    PlantOrigin(id: 'c8d42db8-37bc-4d2b-af01-5555dbcfcd6a', name: 'ယိုးဒယား Import', code: 'thai_import', sortOrder: 1, isActive: true),
    PlantOrigin(id: 'acf51788-2fa6-443a-8a8b-be818928e7bd', name: 'တရုတ် Import', code: 'china_import', sortOrder: 2, isActive: true),
    PlantOrigin(id: 'b060d1fe-8559-4f41-861d-492d2bbd35c7', name: 'ပြည်တွင်း', code: 'local', sortOrder: 3, isActive: true),
  ];

  /// List all plant origins from backend
  Future<List<PlantOrigin>> getOrigins({String? search, bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive,
      };
      final data = await _apiClient.get('/plant-origins', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => PlantOrigin.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return kDefaultOrigins;
  }

  /// Create a new plant origin
  Future<PlantOrigin> createOrigin({
    required String name,
    String? code,
    int sortOrder = 0,
  }) async {
    final data = await _apiClient.post('/plant-origins', body: {
      'name': name.trim(),
      if (code != null && code.isNotEmpty) 'code': code.trim(),
      'sortOrder': sortOrder,
    });
    if (data is Map<String, dynamic>) {
      return PlantOrigin.fromJson(data);
    }
    return PlantOrigin(
      id: 'origin_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      code: code,
      sortOrder: sortOrder,
      isActive: true,
    );
  }

  /// Update existing plant origin
  Future<PlantOrigin> updateOrigin(
    String id, {
    String? name,
    String? code,
    int? sortOrder,
    bool? isActive,
  }) async {
    final data = await _apiClient.patch('/plant-origins/$id', body: {
      if (name != null) 'name': name.trim(),
      if (code != null) 'code': code.trim(),
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (isActive != null) 'isActive': isActive,
    });
    if (data is Map<String, dynamic>) {
      return PlantOrigin.fromJson(data);
    }
    return PlantOrigin(
      id: id,
      name: name ?? '',
      code: code,
      sortOrder: sortOrder ?? 0,
      isActive: isActive ?? true,
    );
  }

  /// Delete or soft-delete plant origin
  Future<bool> deleteOrigin(String id) async {
    try {
      await _apiClient.delete('/plant-origins/$id');
      return true;
    } catch (_) {
      return false;
    }
  }
}

