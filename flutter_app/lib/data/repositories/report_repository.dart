// lib/data/repositories/report_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportRepository(apiClient: apiClient);
});

class ReportRepository {
  final ApiClient _apiClient;

  ReportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get sales report summary
  Future<Map<String, dynamic>> getSalesSummary({
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final data = await _apiClient.get('/reports/sales-summary', queryParams: queryParams);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return {};
  }

  /// Get purchases report (အဝယ်စာရင်း)
  Future<Map<String, dynamic>> getPurchasesReport({
    String? branchId,
    String? vendorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
      };
      final data = await _apiClient.get('/reports/purchases', queryParams: queryParams);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return {};
  }

  /// Get operating expenses report (OPEX: Salaries + Wastage)
  Future<Map<String, dynamic>> getExpensesReport({
    String? branchId,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (period != null && period.isNotEmpty) 'period': period,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final data = await _apiClient.get('/reports/expenses', queryParams: queryParams);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return {};
  }
}

