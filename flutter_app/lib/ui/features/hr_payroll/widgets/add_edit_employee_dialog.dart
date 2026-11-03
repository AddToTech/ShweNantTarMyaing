// ============================================================
// Add / Edit Employee Dialog
// Form to register or update staff details
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../models/employee.dart';
import '../view_models/employee_notifier.dart';

class AddEditEmployeeDialog extends ConsumerStatefulWidget {
  const AddEditEmployeeDialog({super.key, this.employee});

  final Employee? employee;

  static Future<void> show(BuildContext context, {Employee? employee}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditEmployeeDialog(employee: employee),
    );
  }

  @override
  ConsumerState<AddEditEmployeeDialog> createState() =>
      _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends ConsumerState<AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _salaryCtrl;
  late String _selectedRole;
  late String _selectedBranch;
  late DateTime _joinDate;
  late bool _isActive;

  final List<String> _roleOptions = [
    'Manager',
    'Cashier',
    'Gardener',
    'Delivery',
    'Florist',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameCtrl = TextEditingController(text: emp?.name ?? '');
    _phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    _addressCtrl = TextEditingController(text: emp?.address ?? '');
    _salaryCtrl = TextEditingController(
      text: emp != null ? emp.basicSalary.toStringAsFixed(0) : '350000',
    );
    _selectedRole = emp?.role ?? 'Cashier';
    _selectedBranch = emp?.branchId ?? 'branch_a';
    _joinDate = emp?.joinDate ?? DateTime.now();
    _isActive = emp?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final basicSalary = double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0.0;
    final notifier = ref.read(employeeProvider.notifier);

    if (widget.employee == null) {
      // Create new
      final created = await notifier.addEmployee(
        branchId: _selectedBranch,
        name: _nameCtrl.text.trim(),
        role: _selectedRole,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        basicSalary: basicSalary,
        joinDate: _joinDate,
        isActive: _isActive,
      );
      if (created == null || !mounted) return;
    } else {
      // Update existing
      final ok = await notifier.updateEmployee(
        widget.employee!.copyWith(
          branchId: _selectedBranch,
          name: _nameCtrl.text.trim(),
          role: _selectedRole,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          clearPhone: _phoneCtrl.text.trim().isEmpty,
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          clearAddress: _addressCtrl.text.trim().isEmpty,
          basicSalary: basicSalary,
          joinDate: _joinDate,
          isActive: _isActive,
        ),
      );
      if (!ok || !mounted) return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog Header ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
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
                            isEditing
                                ? 'ဝန်ထမ်းအချက်အလက် ပြင်ဆင်မည်'
                                : 'ဝန်ထမ်းအသစ် ထည့်သွင်းမည်',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'ဝန်ထမ်း၏ အချက်အလက်နှင့် အခြေခံလစာကို မွမ်းမံပါ'
                                : 'အမည်၊ တာဝန်ကျဆိုင်ခွဲနှင့် အခြေခံလစာ သတ်မှတ်ပါ',
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
                const SizedBox(height: 20),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // ── Form Scrollable Area ───────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildLabel('ဝန်ထမ်းအမည် (Name) *'),
                        TextFormField(
                          controller: _nameCtrl,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration('ဥပမာ - မသီတာထွေး'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'ဝန်ထမ်းအမည် ထည့်သွင်းပါ' : null,
                        ),
                        const SizedBox(height: 14),

                        // Role & Branch Row
                        Row(
                          children: [
                            // Role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('ရာထူး/တာဝန် (Role) *'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedRole,
                                    dropdownColor: AppColors.surfaceVariant,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration(''),
                                    items: _roleOptions.map((r) {
                                      final burmese = EmployeeRole.fromCode(r).burmeseLabel;
                                      return DropdownMenuItem(
                                        value: r,
                                        child: Text(burmese, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedRole = v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Branch
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('တာဝန်ကျ ဆိုင်ခွဲ (Branch) *'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedBranch,
                                    dropdownColor: AppColors.surfaceVariant,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration(''),
                                    items: kBranches.entries.map((e) {
                                      return DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedBranch = v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Basic Salary & Phone Row
                        Row(
                          children: [
                            // Basic Salary
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('အခြေခံလစာ (Basic Salary Ks) *'),
                                  TextFormField(
                                    controller: _salaryCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: _inputDecoration('ဥပမာ - 350000').copyWith(
                                      suffixText: 'Ks',
                                      suffixStyle: TextStyle(color: AppColors.textMuted),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'အခြေခံလစာ ထည့်သွင်းပါ';
                                      }
                                      final num = double.tryParse(v.replaceAll(',', ''));
                                      if (num == null || num <= 0) {
                                        return 'မှန်ကန်သော လစာပမာဏ ရိုက်ထည့်ပါ';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('ဖုန်းနံပါတ် (Phone)'),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                    decoration: _inputDecoration('09-xxxxxxxxx'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Join Date & Active Switch Row
                        Row(
                          children: [
                            // Join Date Picker
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('စတင်ဝင်ရောက်သည့်ရက်စွဲ (Join Date)'),
                                  InkWell(
                                    onTap: _pickJoinDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_month_rounded,
                                              size: 18, color: AppColors.primary),
                                          const SizedBox(width: 10),
                                          Text(
                                            dateFmt.format(_joinDate),
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Active Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('အလုပ်လုပ်နေဆဲ အခြေအနေ'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _isActive ? 'လက်ရှိဝန်ထမ်း (Active)' : 'အနားယူ (Inactive)',
                                          style: TextStyle(
                                            color: _isActive ? AppColors.primary : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Switch(
                                          value: _isActive,
                                          activeThumbColor: AppColors.primary,
                                          onChanged: (v) => setState(() => _isActive = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Address Field
                        _buildLabel('နေရပ်လိပ်စာ (Address)'),
                        TextFormField(
                          controller: _addressCtrl,
                          maxLines: 2,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _inputDecoration('မြို့နယ်၊ တိုင်းဒေသကြီး...'),
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
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        isEditing ? 'သိမ်းဆည်းမည် (Update)' : 'အသစ်ထည့်မည် (Save)',
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
