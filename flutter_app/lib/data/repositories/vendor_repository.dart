// lib/data/repositories/vendor_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../ui/features/purchases/view_models/vendor_notifier.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VendorRepository(apiClient: apiClient);
});

class VendorRepository {
  final ApiClient _apiClient;

  VendorRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static Vendor _vendorFromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      notes: map['notes']?.toString(),
      isActive: map['is_active'] != false,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// List all vendors
  Future<List<Vendor>> getVendors({String? search, bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive,
      };
      final data = await _apiClient.get('/vendors', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => _vendorFromMap(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Create vendor
  Future<Vendor> createVendor({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    };
    final data = await _apiClient.post('/vendors', body: payload);
    return _vendorFromMap(data as Map<String, dynamic>);
  }

  /// Update vendor
  Future<Vendor> updateVendor(String id, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch('/vendors/$id', body: payload);
    return _vendorFromMap(data as Map<String, dynamic>);
  }

  /// Toggle vendor status
  Future<void> toggleVendor(String id) async {
    await _apiClient.patch('/vendors/$id/toggle');
  }
}

