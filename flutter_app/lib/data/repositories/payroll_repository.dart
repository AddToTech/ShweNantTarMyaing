// lib/data/repositories/payroll_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../ui/features/hr_payroll/models/payroll.dart';
import '../mock/mock_products.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PayrollRepository(apiClient: apiClient);
});

class PayrollRepository {
  final ApiClient _apiClient;

  PayrollRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static PayrollPaymentMethod _parseMethod(dynamic val) {
    final str = val?.toString().toLowerCase() ?? 'cash';
    if (str.contains('kpay')) return PayrollPaymentMethod.kpay;
    if (str.contains('bank')) return PayrollPaymentMethod.banking;
    return PayrollPaymentMethod.cash;
  }

  static Payroll _payrollFromMap(Map<String, dynamic> map) {
    final basic = (map['basic_salary'] is num) ? (map['basic_salary'] as num).toDouble() : double.tryParse(map['basic_salary']?.toString() ?? '') ?? 0.0;
    final bonus = (map['bonus_amount'] is num) ? (map['bonus_amount'] as num).toDouble() : double.tryParse(map['bonus_amount']?.toString() ?? '') ?? 0.0;
    final deduction = (map['deduction_amount'] is num) ? (map['deduction_amount'] as num).toDouble() : double.tryParse(map['deduction_amount']?.toString() ?? '') ?? 0.0;
    final net = (map['net_salary'] is num) ? (map['net_salary'] as num).toDouble() : basic + bonus - deduction;

    return Payroll(
      id: map['id']?.toString() ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      employeeName: map['employee_name']?.toString() ?? '',
      employeeRole: map['employee_role']?.toString() ?? '',
      branchId: normalizeBranchId(
        map['branch_id']?.toString(),
        branchName: map['branch_name']?.toString(),
      ),
      payrollPeriod: map['payroll_period']?.toString() ?? '',
      basicSalary: basic,
      bonusAmount: bonus,
      bonusDescription: map['bonus_description']?.toString(),
      deductionAmount: deduction,
      deductionDescription: map['deduction_description']?.toString(),
      netSalary: net,
      paymentMethod: _parseMethod(map['payment_method']),
      paymentDate: map['payment_date'] != null ? DateTime.tryParse(map['payment_date'].toString()) ?? DateTime.now() : DateTime.now(),
      paidBy: map['paid_by']?.toString(),
      paidByName: map['paid_by_name']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// List payroll records
  Future<List<Payroll>> getPayrolls({
    String? branchId,
    String? payrollPeriod,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (payrollPeriod != null && payrollPeriod.isNotEmpty) 'payrollPeriod': payrollPeriod,
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final data = await _apiClient.get('/payrolls', queryParams: queryParams);
      if (data is List) {
        return data.map((json) => _payrollFromMap(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Disburse salary
  Future<Payroll> disburseSalary(Map<String, dynamic> payload) async {
    final data = await _apiClient.post('/payrolls', body: payload);
    return _payrollFromMap(data as Map<String, dynamic>);
  }

  /// Get payroll expense summary
  Future<List<Map<String, dynamic>>> getSummary({String? branchId, String? payrollPeriod}) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (payrollPeriod != null && payrollPeriod.isNotEmpty) 'payrollPeriod': payrollPeriod,
      };
      final data = await _apiClient.get('/payrolls/summary', queryParams: queryParams);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return const [];
  }
}

