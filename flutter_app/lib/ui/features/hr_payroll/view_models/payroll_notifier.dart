// ============================================================
// Payroll State Notifier & Riverpod Providers
// Manages Salary Disbursement, Deductions, Bonuses, and History
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/payroll_repository.dart';
import '../models/payroll.dart';

// ── Payroll Filter State ─────────────────────────────────────
class PayrollFilterState {
  const PayrollFilterState({
    this.period = 'all',
    this.branchId = 'all',
    this.searchQuery = '',
    this.paymentMethod,
  });

  final String period; // e.g. '2026-10' or 'all'
  final String branchId; // 'all' or branch id
  final String searchQuery;
  final PayrollPaymentMethod? paymentMethod;

  PayrollFilterState copyWith({
    String? period,
    String? branchId,
    String? searchQuery,
    PayrollPaymentMethod? paymentMethod,
    bool clearMethod = false,
  }) {
    return PayrollFilterState(
      period: period ?? this.period,
      branchId: branchId ?? this.branchId,
      searchQuery: searchQuery ?? this.searchQuery,
      paymentMethod: clearMethod ? null : (paymentMethod ?? this.paymentMethod),
    );
  }
}

class PayrollFilterNotifier extends Notifier<PayrollFilterState> {
  @override
  PayrollFilterState build() => const PayrollFilterState();

  void setPeriod(String p) => state = state.copyWith(period: p);
  void setBranch(String b) => state = state.copyWith(branchId: b);
  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);
  void setPaymentMethod(PayrollPaymentMethod? m) =>
      state = state.copyWith(paymentMethod: m, clearMethod: m == null);
}

final payrollFilterProvider =
    NotifierProvider<PayrollFilterNotifier, PayrollFilterState>(
  PayrollFilterNotifier.new,
);

final payrollLoadingProvider = StateProvider<bool>((ref) => true);

// ── Payroll Notifier ──────────────────────────────────────────
class PayrollNotifier extends Notifier<List<Payroll>> {
  @override
  List<Payroll> build() {
    _loadFromRemote();
    return const [];
  }

  Future<void> loadPayrolls() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    ref.read(payrollLoadingProvider.notifier).state = true;
    try {
      final remote = await ref.read(payrollRepositoryProvider).getPayrolls();
      state = remote;
    } catch (_) {
    } finally {
      ref.read(payrollLoadingProvider.notifier).state = false;
    }
  }

  Future<Payroll?> disburseSalary({
    required String employeeId,
    required String employeeName,
    required String employeeRole,
    required String branchId,
    required String payrollPeriod,
    required double basicSalary,
    double bonusAmount = 0.0,
    String? bonusDescription,
    double deductionAmount = 0.0,
    String? deductionDescription,
    PayrollPaymentMethod paymentMethod = PayrollPaymentMethod.cash,
    String? paidBy,
    String? paidByName,
    String? notes,
    DateTime? paymentDate,
  }) async {
    try {
      final created = await ref.read(payrollRepositoryProvider).disburseSalary({
        'employeeId': employeeId,
        'branchId': branchId,
        'payrollPeriod': payrollPeriod,
        'basicSalary': basicSalary,
        'bonusAmount': bonusAmount,
        'bonusDescription': bonusDescription?.trim(),
        'deductionAmount': deductionAmount,
        'deductionDescription': deductionDescription?.trim(),
        'paymentMethod': paymentMethod.code,
        'paymentDate': (paymentDate ?? DateTime.now()).toIso8601String(),
        'notes': notes?.trim(),
      });
      state = [created, ...state];
      return created;
    } catch (_) {
      return null;
    }
  }

  void deletePayroll(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  bool isEmployeePaidForPeriod(String employeeId, String period) {
    return state.any(
      (p) => p.employeeId == employeeId && p.payrollPeriod == period,
    );
  }
}

final payrollProvider =
    NotifierProvider<PayrollNotifier, List<Payroll>>(PayrollNotifier.new);

// ── Filtered Payrolls Provider ────────────────────────────────
final filteredPayrollsProvider = Provider<List<Payroll>>((ref) {
  final payrolls = ref.watch(payrollProvider);
  final filter = ref.watch(payrollFilterProvider);

  return payrolls.where((p) {
    // 1. Period filter
    if (filter.period != 'all' && p.payrollPeriod != filter.period) {
      return false;
    }

    // 2. Branch filter
    if (filter.branchId != 'all' && p.branchId != filter.branchId) {
      return false;
    }

    // 3. Payment method filter
    if (filter.paymentMethod != null && p.paymentMethod != filter.paymentMethod) {
      return false;
    }

    // 4. Search query
    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final nameMatch = p.employeeName.toLowerCase().contains(query);
      final roleMatch = p.employeeRole.toLowerCase().contains(query);
      final periodMatch = p.payrollPeriod.toLowerCase().contains(query);
      final noteMatch = p.notes?.toLowerCase().contains(query) ?? false;
      final bonusMatch = p.bonusDescription?.toLowerCase().contains(query) ?? false;
      final deductionMatch = p.deductionDescription?.toLowerCase().contains(query) ?? false;
      if (!nameMatch && !roleMatch && !periodMatch && !noteMatch && !bonusMatch && !deductionMatch) {
        return false;
      }
    }

    return true;
  }).toList();
});

// ── Payroll Summary KPI Provider ──────────────────────────────
class PayrollSummary {
  const PayrollSummary({
    required this.totalNetPaid,
    required this.totalBasic,
    required this.totalBonus,
    required this.totalDeductions,
    required this.disbursedCount,
  });

  final double totalNetPaid;
  final double totalBasic;
  final double totalBonus;
  final double totalDeductions;
  final int disbursedCount;
}

final payrollSummaryProvider = Provider<PayrollSummary>((ref) {
  final list = ref.watch(filteredPayrollsProvider);

  double net = 0;
  double basic = 0;
  double bonus = 0;
  double deductions = 0;

  for (final p in list) {
    net += p.netSalary;
    basic += p.basicSalary;
    bonus += p.bonusAmount;
    deductions += p.deductionAmount;
  }

  return PayrollSummary(
    totalNetPaid: net,
    totalBasic: basic,
    totalBonus: bonus,
    totalDeductions: deductions,
    disbursedCount: list.length,
  );
});

