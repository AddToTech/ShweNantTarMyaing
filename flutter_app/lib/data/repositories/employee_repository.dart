// lib/data/repositories/employee_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../ui/features/hr_payroll/models/employee.dart';
import '../mock/mock_products.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeRepository(apiClient: apiClient);
});

class EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static Employee _employeeFromMap(Map<String, dynamic> map) {
    final salary = (map['basic_salary'] is num)
        ? (map['basic_salary'] as num).toDouble()
        : double.tryParse(map['basic_salary']?.toString() ?? '') ?? 0.0;

    return Employee(
      id: map['id']?.toString() ?? '',
      branchId: normalizeBranchId(
        map['branch_id']?.toString(),
        branchName: map['branch_name']?.toString(),
      ),
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'General',
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      basicSalary: salary,
      joinDate: map['join_date'] != null ? DateTime.tryParse(map['join_date'].toString()) ?? DateTime.now() : DateTime.now(),
      isActive: map['is_active'] != false,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// List employees
  Future<List<Employee>> getEmployees({
    String? branchId,
    bool? isActive,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (isActive != null) 'isActive': isActive,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final data = await _apiClient.get('/employees', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => _employeeFromMap(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Create employee
  Future<Employee> createEmployee(Map<String, dynamic> payload) async {
    final data = await _apiClient.post('/employees', body: payload);
    return _employeeFromMap(data as Map<String, dynamic>);
  }

  /// Update employee
  Future<Employee> updateEmployee(String id, Map<String, dynamic> payload) async {
    final data = await _apiClient.patch('/employees/$id', body: payload);
    return _employeeFromMap(data as Map<String, dynamic>);
  }

  /// Toggle active status
  Future<void> toggleEmployee(String id) async {
    await _apiClient.patch('/employees/$id/toggle');
  }

  /// Delete (deactivate) employee
  Future<void> deleteEmployee(String id) async {
    await _apiClient.delete('/employees/$id');
  }
}

