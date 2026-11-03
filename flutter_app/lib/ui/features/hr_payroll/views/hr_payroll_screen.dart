// ============================================================
// HrPayrollScreen — ဝန်ထမ်းနှင့် လစာစီမံခန့်ခွဲမှု (HR & Payroll)
// Tablet-optimized layout with:
//   - Header: Quick Actions (Add Employee, Disburse Salary)
//   - KPI Summary Cards: Staff count, Net Disbursed, Basic, Bonus, Fines
//   - Tab 0: ဝန်ထမ်းများ စာရင်း (EmployeeListView)
//   - Tab 1: လစာထုတ်ပေးမှု မှတ်တမ်း (PayrollHistoryView)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../view_models/employee_notifier.dart';
import '../view_models/payroll_notifier.dart';
import '../widgets/add_edit_employee_dialog.dart';
import '../widgets/disburse_salary_dialog.dart';
import '../widgets/employee_list_view.dart';
import '../widgets/payroll_history_view.dart';

class HrPayrollScreen extends ConsumerStatefulWidget {
  const HrPayrollScreen({super.key});

  @override
  ConsumerState<HrPayrollScreen> createState() => _HrPayrollScreenState();
}

class _HrPayrollScreenState extends ConsumerState<HrPayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final activeEmployees = ref.watch(activeEmployeesProvider);
    final allEmployees = ref.watch(filteredEmployeesProvider);
    final summary = ref.watch(payrollSummaryProvider);
    final filteredPayrolls = ref.watch(filteredPayrollsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top Header & KPI Summary Section ─────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title + Action Buttons Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ဝန်ထမ်းနှင့် လစာစီမံခန့်ခွဲမှု (HR & Payroll)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ဝန်ထမ်းအချက်အလက် (CRUD)၊ လစာထုတ်ပေးခြင်း၊ အပိုဆု/ဒဏ်ကြေးနှင့် အပူပေးပြေစာ (Payslip)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Action: Add Employee
                    OutlinedButton.icon(
                      onPressed: () => AddEditEmployeeDialog.show(context),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                      label: const Text(
                        'ဝန်ထမ်းအသစ်',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Quick Action: Disburse Salary
                    FilledButton.icon(
                      onPressed: () => DisburseSalaryDialog.show(context),
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text(
                        'လစာထုတ်ပေးမည်',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. KPI Summary Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        _KpiCard(
                          title: 'လက်ရှိဝန်ထမ်း (Active)',
                          value: '${activeEmployees.length} ယောက်',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'အခြေခံလစာ စုစုပေါင်း',
                          value: '${currencyFmt.format(summary.totalBasic)} Ks',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'အပိုဆု/ချီးမြှင့်ငွေ (Bonus)',
                          value: '+${currencyFmt.format(summary.totalBonus)} Ks',
                          icon: Icons.card_giftcard_rounded,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'ဒဏ်ကြေး/နုတ်ငွေ (Deduction)',
                          value: '-${currencyFmt.format(summary.totalDeductions)} Ks',
                          icon: Icons.remove_circle_outline_rounded,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'စုစုပေါင်း အသားတင်လစာ (Net OPEX)',
                          value: '${currencyFmt.format(summary.totalNetPaid)} Ks',
                          subtitle: '${summary.disbursedCount} ကြိမ် ရှင်းပြီး',
                          icon: Icons.payments_rounded,
                          color: AppColors.primary,
                          highlight: true,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 3. Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.badge_outlined, size: 18),
                      child: Row(
                        children: [
                          const Text('ဝန်ထမ်းများ စာရင်း (Employees)'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${allEmployees.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      child: Row(
                        children: [
                          const Text('လစာပေးချေမှု မှတ်တမ်း (Payroll History)'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredPayrolls.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  EmployeeListView(),
                  PayrollHistoryView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Mini Card Widget ──────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.highlight = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? color.withValues(alpha: 0.08) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? color.withValues(alpha: 0.4) : AppColors.border,
            width: highlight ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: highlight ? color : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
