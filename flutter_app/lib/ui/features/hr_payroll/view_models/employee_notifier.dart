// ============================================================
// Employee State Notifier & Riverpod Providers
// Manages Employee CRUD, Branch & Search Filtering
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/employee_repository.dart';
import '../models/employee.dart';

// ── State for Employee Filter ────────────────────────────────
class EmployeeFilterState {
  const EmployeeFilterState({
    this.searchQuery = '',
    this.branchId = 'all',
    this.showInactive = true,
  });

  final String searchQuery;
  final String branchId;
  final bool showInactive;

  EmployeeFilterState copyWith({
    String? searchQuery,
    String? branchId,
    bool? showInactive,
  }) {
    return EmployeeFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      branchId: branchId ?? this.branchId,
      showInactive: showInactive ?? this.showInactive,
    );
  }
}

class EmployeeFilterNotifier extends Notifier<EmployeeFilterState> {
  @override
  EmployeeFilterState build() => const EmployeeFilterState();

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);
  void setBranch(String b) => state = state.copyWith(branchId: b);
  void toggleShowInactive() => state = state.copyWith(showInactive: !state.showInactive);
  void setShowInactive(bool val) => state = state.copyWith(showInactive: val);
}

final employeeFilterProvider =
    NotifierProvider<EmployeeFilterNotifier, EmployeeFilterState>(
  EmployeeFilterNotifier.new,
);

final employeeLoadingProvider = StateProvider<bool>((ref) => true);

// ── Employee List Notifier ────────────────────────────────────
class EmployeeNotifier extends Notifier<List<Employee>> {
  @override
  List<Employee> build() {
    _loadFromRemote();
    return const [];
  }

  Future<void> loadEmployees() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    ref.read(employeeLoadingProvider.notifier).state = true;
    try {
      final remote = await ref.read(employeeRepositoryProvider).getEmployees();
      state = remote;
    } catch (_) {
    } finally {
      ref.read(employeeLoadingProvider.notifier).state = false;
    }
  }

  Future<Employee?> addEmployee({
    required String branchId,
    required String name,
    required String role,
    String? phone,
    String? address,
    required double basicSalary,
    required DateTime joinDate,
    bool isActive = true,
  }) async {
    try {
      final created = await ref.read(employeeRepositoryProvider).createEmployee({
        'branchId': branchId,
        'name': name.trim(),
        'role': role.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'basicSalary': basicSalary,
        'joinDate': joinDate.toIso8601String().split('T').first,
        'isActive': isActive,
      });
      state = [created, ...state];
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateEmployee(Employee updated) async {
    try {
      await ref.read(employeeRepositoryProvider).updateEmployee(updated.id, {
        'branchId': updated.branchId,
        'name': updated.name,
        'role': updated.role,
        'phone': updated.phone,
        'address': updated.address,
        'basicSalary': updated.basicSalary,
        'joinDate': updated.joinDate.toIso8601String().split('T').first,
        'isActive': updated.isActive,
      });
      state = [
        for (final emp in state)
          if (emp.id == updated.id) updated else emp,
      ];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleActive(String id) async {
    try {
      await ref.read(employeeRepositoryProvider).toggleEmployee(id);
      state = [
        for (final emp in state)
          if (emp.id == id) emp.copyWith(isActive: !emp.isActive) else emp,
      ];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      await ref.read(employeeRepositoryProvider).deleteEmployee(id);
      state = state.where((emp) => emp.id != id).toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  Employee? getEmployeeById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final employeeProvider =
    NotifierProvider<EmployeeNotifier, List<Employee>>(EmployeeNotifier.new);

// ── Filtered Employees Provider ───────────────────────────────
final filteredEmployeesProvider = Provider<List<Employee>>((ref) {
  final employees = ref.watch(employeeProvider);
  final filter = ref.watch(employeeFilterProvider);

  return employees.where((emp) {
    // 1. Branch filter
    if (filter.branchId != 'all' && emp.branchId != filter.branchId) {
      return false;
    }

    // 2. Active status filter
    if (!filter.showInactive && !emp.isActive) {
      return false;
    }

    // 3. Search query filter
    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final nameMatch = emp.name.toLowerCase().contains(query);
      final roleMatch = emp.role.toLowerCase().contains(query);
      final phoneMatch = emp.phone?.toLowerCase().contains(query) ?? false;
      if (!nameMatch && !roleMatch && !phoneMatch) {
        return false;
      }
    }

    return true;
  }).toList();
});

// ── Active Employees Provider (e.g. for dropdowns) ─────────────
final activeEmployeesProvider = Provider<List<Employee>>((ref) {
  final employees = ref.watch(employeeProvider);
  return employees.where((e) => e.isActive).toList();
});

