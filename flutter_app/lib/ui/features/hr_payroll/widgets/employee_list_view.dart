// ============================================================
// Employee List View
// Search, Branch filter, Active/Inactive toggle, Employee Cards & Actions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../view_models/employee_notifier.dart';
import 'add_edit_employee_dialog.dart';
import 'disburse_salary_dialog.dart';
import '../../../shared/widgets/loading_view.dart';

class EmployeeListView extends ConsumerWidget {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(branchesProvider);
    final employees = ref.watch(filteredEmployeesProvider);
    final isEmployeeLoading = ref.watch(employeeLoadingProvider);
    final filter = ref.watch(employeeFilterProvider);
    final filterNotifier = ref.read(employeeFilterProvider.notifier);
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Column(
      children: [
        // ── Filter & Search Toolbar ──────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: filterNotifier.setSearchQuery,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ဝန်ထမ်းအမည်၊ ရာထူး သို့မဟုတ် ဖုန်းနံပါတ်ဖြင့် ရှာဖွေပါ...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Branch Dropdown Filter
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ['all', ...kBranches.keys].contains(filter.branchId) ? filter.branchId : 'all',
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('ဆိုင်ခွဲအားလုံး (All Branches)',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      ...kBranches.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      if (v != null) filterNotifier.setBranch(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Active / Inactive Switch
              InkWell(
                onTap: filterNotifier.toggleShowInactive,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: filter.showInactive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: filter.showInactive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filter.showInactive
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 16,
                        color: filter.showInactive ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter.showInactive ? 'အနားယူဝန်ထမ်းများ ပြပါ' : 'လက်ရှိဝန်ထမ်းများသာ',
                        style: TextStyle(
                          color: filter.showInactive ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Add Employee Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  AddEditEmployeeDialog.show(context);
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text(
                  'ဝန်ထမ်းအသစ်ထည့်မည်',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Employees List / Cards ───────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(employeeProvider.notifier).loadEmployees(),
              ]);
            },
            child: isEmployeeLoading && employees.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'ဝန်ထမ်းစာရင်းများ ရယူနေပါသည်...',
                      subMessage: 'Loading employees...',
                      icon: Icons.badge_outlined,
                    ),
                  )
                : employees.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                    final emp = employees[index];
                    final branchName = kBranches[emp.branchId] ?? emp.branchId;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: emp.isActive
                              ? AppColors.border
                              : AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: emp.isActive
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceVariant,
                            child: Text(
                              emp.name.isNotEmpty ? emp.name.characters.first : 'E',
                              style: TextStyle(
                                color: emp.isActive ? AppColors.primary : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Employee Info
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      emp.name,
                                      style: TextStyle(
                                        color: emp.isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRoleBadge(emp.role),
                                    if (!emp.isActive) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Inactive',
                                          style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(Icons.storefront_rounded, size: 14, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 170,
                                      child: Text(
                                        branchName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(Icons.phone_rounded, size: 14, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        emp.phone ?? 'ဖုန်းမရှိပါ',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Basic Salary
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'အခြေခံလစာ (Basic Salary)',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currencyFmt.format(emp.basicSalary)} Ks',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Join Date
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'စတင်ဝင်ရောက်ရက်',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFmt.format(emp.joinDate),
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quick Pay Salary Button
                              if (emp.isActive)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    DisburseSalaryDialog.show(
                                      context,
                                      preselectedEmployeeId: emp.id,
                                    );
                                  },
                                  icon: const Icon(Icons.payment_rounded, size: 16),
                                  label: const Text(
                                    'လစာရှင်းမည်',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(width: 8),

                              // Edit Button
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                tooltip: 'ပြင်ဆင်မည်',
                                onPressed: () {
                                  AddEditEmployeeDialog.show(context, employee: emp);
                                },
                              ),

                              // Toggle Active Status Switch
                              Tooltip(
                                message: emp.isActive ? 'အနားယူထားရန် ပြောင်းမည်' : 'ပြန်လည်တာဝန်ပေးမည်',
                                child: Switch(
                                  value: emp.isActive,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (_) {
                                    ref.read(employeeProvider.notifier).toggleActive(emp.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg = AppColors.surfaceVariant;
    Color fg = AppColors.textSecondary;

    switch (role.toLowerCase()) {
      case 'manager':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade300;
        break;
      case 'cashier':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.lightBlueAccent;
        break;
      case 'gardener':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.lightGreenAccent;
        break;
      case 'delivery':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purpleAccent.shade100;
        break;
      case 'florist':
        bg = Colors.pink.withValues(alpha: 0.15);
        fg = Colors.pinkAccent.shade100;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'ကိုက်ညီသော ဝန်ထမ်းစာရင်း မရှိပါ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ရှာဖွေမှုစာသား သို့မဟုတ် ဆိုင်ခွဲရွေးချယ်မှုကို ပြောင်းလဲကြည့်ပါ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
