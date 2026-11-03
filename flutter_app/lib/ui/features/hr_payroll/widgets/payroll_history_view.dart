// ============================================================
// Payroll History View
// Table displaying past salary disbursements, filters, and payslip triggers
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../models/payroll.dart';
import '../view_models/employee_notifier.dart';
import '../view_models/payroll_notifier.dart';
import 'disburse_salary_dialog.dart';
import 'payslip_dialog.dart';
import '../../../shared/widgets/loading_view.dart';

class PayrollHistoryView extends ConsumerWidget {
  const PayrollHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(branchesProvider);
    final payrolls = ref.watch(filteredPayrollsProvider);
    final allPayrolls = ref.watch(payrollProvider);
    final isPayrollLoading = ref.watch(payrollLoadingProvider);
    final filter = ref.watch(payrollFilterProvider);
    final filterNotifier = ref.read(payrollFilterProvider.notifier);

    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    // Extract unique periods from all payroll records + current month
    final now = DateTime.now();
    final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final periods = {
      currentPeriod,
      if (filter.period != 'all') filter.period,
      for (final p in allPayrolls) p.payrollPeriod,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final periodOptions = ['all', ...periods];
    final effectivePeriod = periodOptions.contains(filter.period) ? filter.period : 'all';

    final branchOptions = ['all', ...kBranches.keys];
    final effectiveBranchId = branchOptions.contains(filter.branchId) ? filter.branchId : 'all';

    return Column(
      children: [
        // ── Filter Toolbar ─────────────────────────────────────────
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
                      hintText: 'ဝန်ထမ်းအမည်၊ ရာထူး သို့မဟုတ် မှတ်ချက်ဖြင့် ရှာဖွေပါ...',
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
              const SizedBox(width: 12),

              // Period Filter Dropdown
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
                    value: effectivePeriod,
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('ကာလအားလုံး (All Periods)',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      ...periods.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      if (v != null) filterNotifier.setPeriod(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Branch Filter Dropdown
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
                    value: effectiveBranchId,
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
              const SizedBox(width: 12),

              // Payment Method Filter
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PayrollPaymentMethod?>(
                    value: filter.paymentMethod,
                    dropdownColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('ငွေပေးစနစ်အားလုံး',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      ...PayrollPaymentMethod.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.label,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: (v) => filterNotifier.setPaymentMethod(v),
                  ),
                ),
              ),

              const Spacer(),

              // Quick Disburse Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  DisburseSalaryDialog.show(context);
                },
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text(
                  'လစာထုတ်ပေးမည်',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Payroll History Table ──────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(payrollProvider.notifier).loadPayrolls(),
                ref.read(employeeProvider.notifier).loadEmployees(),
              ]);
            },
            child: isPayrollLoading && payrolls.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'လစာရှင်းတမ်း မှတ်တမ်းများ ရယူနေပါသည်...',
                      subMessage: 'Loading payroll history...',
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                : payrolls.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1000),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                            horizontalMargin: 16,
                            columnSpacing: 20,
                            columns: [
                              DataColumn(label: Text('ကာလ / စလစ် ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ဝန်ထမ်း (အမည် & ရာထူး)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ဆိုင်ခွဲ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('အခြေခံလစာ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ချီးမြှင့်ငွေ (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ဒဏ်ကြေး (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('အသားတင်လစာ (Net)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ငွေပေးစနစ်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('ရက်စွဲ/အချိန်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                              DataColumn(label: Text('စလစ်ပြေစာ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                            ],
                            rows: payrolls.map((p) {
                              final branch = kBranches[p.branchId] ?? p.branchId;

                              return DataRow(
                                cells: [
                                  // Period & Slip ID
                                  DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.payrollPeriod,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                                        Text(p.id,
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                      ],
                                    ),
                                  ),

                                  // Employee Name & Role
                                  DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.employeeName,
                                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                                        Text(p.employeeRole,
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),

                                  // Branch
                                  DataCell(
                                    Text(branch,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ),

                                  // Basic Salary
                                  DataCell(
                                    Text('${currencyFmt.format(p.basicSalary)} Ks',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                  ),

                                  // Bonus
                                  DataCell(
                                    Tooltip(
                                      message: p.bonusDescription ?? 'ချီးမြှင့်ငွေ မရှိပါ',
                                      child: Text(
                                        p.bonusAmount > 0
                                            ? '+${currencyFmt.format(p.bonusAmount)} Ks'
                                            : '-',
                                        style: TextStyle(
                                          color: p.bonusAmount > 0 ? Colors.green : AppColors.textMuted,
                                          fontWeight: p.bonusAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Deduction
                                  DataCell(
                                    Tooltip(
                                      message: p.deductionDescription ?? 'ဒဏ်ကြေး မရှိပါ',
                                      child: Text(
                                        p.deductionAmount > 0
                                            ? '-${currencyFmt.format(p.deductionAmount)} Ks'
                                            : '-',
                                        style: TextStyle(
                                          color: p.deductionAmount > 0 ? Colors.redAccent : AppColors.textMuted,
                                          fontWeight: p.deductionAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Net Salary
                                  DataCell(
                                    Text(
                                      '${currencyFmt.format(p.netSalary)} Ks',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                  // Payment Method
                                  DataCell(
                                    _buildPaymentMethodBadge(p.paymentMethod),
                                  ),

                                  // Payment Date
                                  DataCell(
                                    Text(dateFmt.format(p.paymentDate),
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ),

                                  // Payslip Button
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.receipt_rounded,
                                          color: AppColors.primary, size: 20),
                                      tooltip: 'လစာစလစ် ကြည့်မည်/ထုတ်မည်',
                                      onPressed: () {
                                        PayslipDialog.show(context, payroll: p);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodBadge(PayrollPaymentMethod method) {
    Color color = AppColors.primary;
    if (method == PayrollPaymentMethod.kpay) color = Colors.blue;
    if (method == PayrollPaymentMethod.banking) color = Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(method.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            method.code.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'လစာပေးချေမှု မှတ်တမ်း မရှိပါ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ရွေးချယ်ထားသော ကာလ သို့မဟုတ် ဆိုင်ခွဲအတွက် လစာရှင်းတမ်း မတွေ့ရှိပါ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
