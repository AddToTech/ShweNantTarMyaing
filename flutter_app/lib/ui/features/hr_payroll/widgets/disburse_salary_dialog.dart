// ============================================================
// Disburse Salary Dialog
// Interactive form for paying monthly salaries, bonuses, and fine deductions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../models/employee.dart';
import '../models/payroll.dart';
import '../view_models/employee_notifier.dart';
import '../view_models/payroll_notifier.dart';
import 'payslip_dialog.dart';

class DisburseSalaryDialog extends ConsumerStatefulWidget {
  const DisburseSalaryDialog({
    super.key,
    this.preselectedEmployeeId,
    this.initialPeriod,
  });

  final String? preselectedEmployeeId;
  final String? initialPeriod;

  static Future<Payroll?> show(
    BuildContext context, {
    String? preselectedEmployeeId,
    String? initialPeriod,
  }) {
    return showDialog<Payroll?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DisburseSalaryDialog(
        preselectedEmployeeId: preselectedEmployeeId,
        initialPeriod: initialPeriod,
      ),
    );
  }

  @override
  ConsumerState<DisburseSalaryDialog> createState() =>
      _DisburseSalaryDialogState();
}

class _DisburseSalaryDialogState extends ConsumerState<DisburseSalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEmployeeId;
  late String _selectedPeriod;
  late final TextEditingController _basicSalaryCtrl;
  late final TextEditingController _bonusAmountCtrl;
  late final TextEditingController _bonusDescCtrl;
  late final TextEditingController _deductionAmountCtrl;
  late final TextEditingController _deductionDescCtrl;
  late final TextEditingController _notesCtrl;

  PayrollPaymentMethod _paymentMethod = PayrollPaymentMethod.cash;
  bool _autoPrintPayslip = true;

  final List<String> _quickBonusPresets = [
    'ရောင်းအားဆု (Sales Target Bonus)',
    'အချိန်ပိုကြေး (Overtime Allowance)',
    'သီတင်းကျွတ်/နှစ်သစ် မုန့်ဖိုး (Seasonal Bonus)',
    'အပင်ရှင်သန်မှု ထူးချွန်ဆု (Garden Care Bonus)',
  ];

  final List<String> _quickDeductionPresets = [
    'စဉ့်အိုး/ပစ္စည်း ကွဲရှမှု (Broken Pots / Damages)',
    'ခွင့်မဲ့ ပျက်ကွက် (Unexcused Absence)',
    'ကြိုတင်ထုတ်ယူငွေ (Salary Advance Repayment)',
    'နောက်ကျဒဏ်ကြေး (Late Arrival Penalty)',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = widget.initialPeriod ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _selectedEmployeeId = widget.preselectedEmployeeId;

    _basicSalaryCtrl = TextEditingController(text: '0');
    _bonusAmountCtrl = TextEditingController(text: '0');
    _bonusDescCtrl = TextEditingController();
    _deductionAmountCtrl = TextEditingController(text: '0');
    _deductionDescCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    _basicSalaryCtrl.addListener(_onAmountChanged);
    _bonusAmountCtrl.addListener(_onAmountChanged);
    _deductionAmountCtrl.addListener(_onAmountChanged);

    // If preselected, initialize salary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedEmployeeId != null) {
        final emp = ref
            .read(employeeProvider.notifier)
            .getEmployeeById(_selectedEmployeeId!);
        if (emp != null) {
          _onSelectEmployee(emp);
        }
      }
    });
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _onSelectEmployee(Employee emp) {
    setState(() {
      _selectedEmployeeId = emp.id;
      _basicSalaryCtrl.text = emp.basicSalary.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _basicSalaryCtrl.removeListener(_onAmountChanged);
    _bonusAmountCtrl.removeListener(_onAmountChanged);
    _deductionAmountCtrl.removeListener(_onAmountChanged);
    _basicSalaryCtrl.dispose();
    _bonusAmountCtrl.dispose();
    _bonusDescCtrl.dispose();
    _deductionAmountCtrl.dispose();
    _deductionDescCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _basicSalary =>
      double.tryParse(_basicSalaryCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get _bonusAmount =>
      double.tryParse(_bonusAmountCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get _deductionAmount =>
      double.tryParse(_deductionAmountCtrl.text.replaceAll(',', '')) ?? 0.0;

  double get _netPayable =>
      (_basicSalary + _bonusAmount - _deductionAmount).clamp(0.0, double.infinity);

  void _confirmAndPay() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကျေးဇူးပြု၍ ဝန်ထမ်း ရွေးချယ်ပါ')),
      );
      return;
    }

    final emp = ref
        .read(employeeProvider.notifier)
        .getEmployeeById(_selectedEmployeeId!);
    if (emp == null) return;

    final payrollNotifier = ref.read(payrollProvider.notifier);

    // Check if already paid
    if (payrollNotifier.isEmployeePaidForPeriod(emp.id, _selectedPeriod)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Text('သတိပေးချက်'),
            ],
          ),
          content: Text(
            'ဝန်ထမ်း ${emp.name} အတွက် ကာလ ($_selectedPeriod) တွင် လစာရှင်းတမ်း ထုတ်ပေးပြီးဖြစ်ပါသည်။ ထပ်မံ ထုတ်ပေးလိုပါသလား?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('မလုပ်တော့ပါ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _executePayment(emp);
              },
              child: const Text(
                'ဆက်လက် ထုတ်ပေးမည်',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _executePayment(emp);
  }

  Future<void> _executePayment(Employee emp) async {
    final payrollNotifier = ref.read(payrollProvider.notifier);
    final currentUser = ref.read(authProvider).currentUser;

    final payroll = await payrollNotifier.disburseSalary(
      employeeId: emp.id,
      employeeName: emp.name,
      employeeRole: emp.role,
      branchId: emp.branchId,
      payrollPeriod: _selectedPeriod,
      basicSalary: _basicSalary,
      bonusAmount: _bonusAmount,
      bonusDescription: _bonusDescCtrl.text.trim().isEmpty ? null : _bonusDescCtrl.text.trim(),
      deductionAmount: _deductionAmount,
      deductionDescription: _deductionDescCtrl.text.trim().isEmpty ? null : _deductionDescCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      paidBy: currentUser?.id,
      paidByName: currentUser?.name ?? 'Admin',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (payroll == null || !mounted) return;
    Navigator.of(context).pop(payroll);

    if (_autoPrintPayslip) {
      showDialog(
        context: context,
        builder: (_) => PayslipDialog(payroll: payroll),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeProvider);
    final activeEmployees = employees.where((e) => e.isActive).toList();
    final currencyFmt = NumberFormat('#,###');

    final selectedEmp = employees.where((e) => e.id == _selectedEmployeeId).firstOrNull;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'လစာနှင့် ချီးမြှင့်ငွေ ရှင်းတမ်း ထုတ်ပေးမည်',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'အခြေခံလစာ၊ ချီးမြှင့်ငွေနှင့် ဒဏ်ကြေးများကို တွက်ချက်၍ လစာပေးချေပါ',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // ── Form Content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Employee & Period Row
                        Row(
                          children: [
                            // Employee Dropdown
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('ဝန်ထမ်း ရွေးချယ်ပါ (Employee) *'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedEmployeeId,
                                    dropdownColor: AppColors.surfaceVariant,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration(''),
                                    items: (activeEmployees.isNotEmpty ? activeEmployees : employees).map((e) {
                                      final branch = kBranches[e.branchId] ?? e.branchId;
                                      return DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          '${e.name} (${e.role} • $branch)',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final emp = employees.firstWhere((e) => e.id == val);
                                        _onSelectEmployee(emp);
                                      }
                                    },
                                    validator: (v) =>
                                        v == null ? 'ကျေးဇူးပြု၍ ဝန်ထမ်း ရွေးချယ်ပါ' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Payroll Period
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('လစာကာလ (Period) *'),
                                  TextFormField(
                                    initialValue: _selectedPeriod,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration('YYYY-MM'),
                                    onChanged: (v) => _selectedPeriod = v.trim(),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty ? 'ကာလ ထည့်ပါ' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (selectedEmp != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'တာဝန်ကျ: ${kBranches[selectedEmp.branchId] ?? selectedEmp.branchId}  |  ဖုန်း: ${selectedEmp.phone ?? "မရှိပါ"}',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // 2. Basic Salary Input
                        _buildLabel('အခြေခံလစာ (Basic Salary Ks) *'),
                        TextFormField(
                          controller: _basicSalaryCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: _inputDecoration('အခြေခံလစာ').copyWith(
                            suffixText: 'Ks',
                            suffixStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          validator: (v) {
                            final n = double.tryParse(v?.replaceAll(',', '') ?? '');
                            if (n == null || n < 0) return 'မှန်ကန်သော လစာ ထည့်ပါ';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 3. Bonus Section (Green Tint Box)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,
                                      color: Colors.green, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '(+) ချီးမြှင့်ငွေ / အပိုဆု (Bonus)',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  // Bonus Amount
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      controller: _bonusAmountCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: _inputDecoration('0 Ks').copyWith(
                                        suffixText: 'Ks',
                                        suffixStyle: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Bonus Description
                                  Expanded(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _bonusDescCtrl,
                                      style: TextStyle(
                                          color: AppColors.textPrimary, fontSize: 13),
                                      decoration: _inputDecoration('အကြောင်းအရင်း / မှတ်ချက်'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _quickBonusPresets.map((preset) {
                                  return ActionChip(
                                    label: Text(preset, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: AppColors.surfaceVariant,
                                    side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                                    onPressed: () {
                                      _bonusDescCtrl.text = preset;
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 4. Deduction / Fine Section (Red Tint Box)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.remove_circle_outline_rounded,
                                      color: Colors.redAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '(-) ဒဏ်ကြေး / နုတ်ငွေ (Deduction / Fine)',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  // Deduction Amount
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      controller: _deductionAmountCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: _inputDecoration('0 Ks').copyWith(
                                        suffixText: 'Ks',
                                        suffixStyle: const TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Deduction Reason
                                  Expanded(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _deductionDescCtrl,
                                      style: TextStyle(
                                          color: AppColors.textPrimary, fontSize: 13),
                                      decoration: _inputDecoration('ဒဏ်ကြေးအကြောင်းအရင်း'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _quickDeductionPresets.map((preset) {
                                  return ActionChip(
                                    label: Text(preset, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: AppColors.surfaceVariant,
                                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                    onPressed: () {
                                      _deductionDescCtrl.text = preset;
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 5. Payment Method Selector
                        _buildLabel('ငွေပေးချေမည့်စနစ် (Payment Method) *'),
                        Row(
                          children: PayrollPaymentMethod.values.map((method) {
                            final selected = _paymentMethod == method;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _paymentMethod = method),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.border,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        method.icon,
                                        size: 18,
                                        color: selected ? AppColors.primary : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        method.label,
                                        style: TextStyle(
                                          color: selected ? AppColors.primary : AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // 6. Notes Field
                        _buildLabel('အထွေထွေ မှတ်ချက် (Notes)'),
                        TextFormField(
                          controller: _notesCtrl,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _inputDecoration('ငွေလွှဲပြေစာနံပါတ် သို့မဟုတ် အခြားအချက်အလက်များ...'),
                        ),

                        const SizedBox(height: 16),

                        // 7. Live Net Calculation Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'အခြေခံလစာ (Basic):',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  Text(
                                    '${currencyFmt.format(_basicSalary)} Ks',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (_bonusAmount > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '(+) ချီးမြှင့်ငွေ (Bonus):',
                                      style: TextStyle(color: Colors.green, fontSize: 12),
                                    ),
                                    Text(
                                      '+${currencyFmt.format(_bonusAmount)} Ks',
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                              if (_deductionAmount > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '(-) ဒဏ်ကြေး (Deduction):',
                                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                    Text(
                                      '-${currencyFmt.format(_deductionAmount)} Ks',
                                      style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: AppColors.border, height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'အသားတင် ပေးချေရမည့် လစာငွေ (Net Payable):',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${currencyFmt.format(_netPayable)} Ks',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Checkbox: Print Payslip
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'ငွေပေးချေပြီးပါက လစာစလစ် ပြေစာ ဖွင့်ပြ/ပရင့်ထုတ်မည် (Print Payslip)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          value: _autoPrintPayslip,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _autoPrintPayslip = v ?? true),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // ── Action Buttons ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('မလုပ်တော့ပါ (Cancel)',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirmAndPay,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        'အတည်ပြု ထုတ်ပေးမည် (${currencyFmt.format(_netPayable)} Ks)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
