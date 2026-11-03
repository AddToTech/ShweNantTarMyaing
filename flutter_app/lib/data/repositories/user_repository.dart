// lib/data/repositories/user_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient: apiClient);
});

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// List users (falls back to /auth/accounts when unauthenticated)
  Future<List<AppUser>> getUsers({
    String? branchId,
    String? role,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive,
      };

      final data = await _apiClient.get(
        '/users',
        queryParams: queryParams,
        suppressErrorToast: true,
      );
      if (data is List) {
        return data.map((json) => AppUser.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      try {
        final fallback = await _apiClient.get(
          '/auth/accounts',
          suppressErrorToast: true,
        );
        if (fallback is List) {
          return fallback
              .map((json) => AppUser.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  /// Create new user
  Future<AppUser> createUser(Map<String, dynamic> payload) async {
    final data = await _apiClient.post('/users', body: payload);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  /// Update user
  Future<AppUser> updateUser(String id, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch('/users/$id', body: payload);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  /// Update password
  Future<void> updatePassword(
    String id, {
    String? oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      '/users/$id/password',
      body: {
        if (oldPassword != null) 'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Toggle user active status
  Future<void> toggleUser(String id) async {
    await _apiClient.patch('/users/$id/toggle');
  }

  /// Delete user account
  Future<void> deleteUser(String id) async {
    await _apiClient.delete('/users/$id');
  }
}

