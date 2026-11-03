// ============================================================
// Payroll Domain Model
// Represents salary disbursements, bonuses, and fine deductions
// ============================================================

import 'package:flutter/material.dart';

enum PayrollPaymentMethod {
  cash(code: 'cash', label: 'ငွေသား (Cash)', icon: Icons.payments_outlined),
  kpay(code: 'kpay', label: 'KBZPay (KPay)', icon: Icons.qr_code_2_rounded),
  banking(code: 'banking', label: 'ဘဏ်လွှဲ (Banking)', icon: Icons.account_balance_rounded);

  const PayrollPaymentMethod({
    required this.code,
    required this.label,
    required this.icon,
  });

  final String code;
  final String label;
  final IconData icon;

  static PayrollPaymentMethod fromCode(String code) {
    for (final m in PayrollPaymentMethod.values) {
      if (m.code.toLowerCase() == code.toLowerCase()) return m;
    }
    return PayrollPaymentMethod.cash;
  }
}

class Payroll {
  const Payroll({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    required this.branchId,
    required this.payrollPeriod,
    required this.basicSalary,
    this.bonusAmount = 0.0,
    this.bonusDescription,
    this.deductionAmount = 0.0,
    this.deductionDescription,
    required this.netSalary,
    this.paymentMethod = PayrollPaymentMethod.cash,
    required this.paymentDate,
    this.paidBy,
    this.paidByName,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final String branchId;
  final String payrollPeriod; // e.g. "2026-10"
  final double basicSalary;
  final double bonusAmount;
  final String? bonusDescription;
  final double deductionAmount;
  final String? deductionDescription;
  final double netSalary; // basicSalary + bonusAmount - deductionAmount
  final PayrollPaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String? paidBy;
  final String? paidByName;
  final String? notes;
  final DateTime createdAt;

  /// Factory helper that automatically calculates netSalary
  factory Payroll.create({
    String? id,
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
    DateTime? paymentDate,
    String? paidBy,
    String? paidByName,
    String? notes,
    DateTime? createdAt,
  }) {
    final net = (basicSalary + bonusAmount - deductionAmount).clamp(0.0, double.infinity);
    final now = DateTime.now();
    return Payroll(
      id: id ?? 'pr_${DateTime.now().microsecondsSinceEpoch}',
      employeeId: employeeId,
      employeeName: employeeName,
      employeeRole: employeeRole,
      branchId: branchId,
      payrollPeriod: payrollPeriod,
      basicSalary: basicSalary,
      bonusAmount: bonusAmount,
      bonusDescription: bonusDescription,
      deductionAmount: deductionAmount,
      deductionDescription: deductionDescription,
      netSalary: net,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate ?? now,
      paidBy: paidBy,
      paidByName: paidByName,
      notes: notes,
      createdAt: createdAt ?? now,
    );
  }

  Payroll copyWith({
    String? employeeId,
    String? employeeName,
    String? employeeRole,
    String? branchId,
    String? payrollPeriod,
    double? basicSalary,
    double? bonusAmount,
    String? bonusDescription,
    bool clearBonusDesc = false,
    double? deductionAmount,
    String? deductionDescription,
    bool clearDeductionDesc = false,
    double? netSalary,
    PayrollPaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? paidBy,
    String? paidByName,
    String? notes,
    bool clearNotes = false,
  }) {
    return Payroll(
      id: id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole,
      branchId: branchId ?? this.branchId,
      payrollPeriod: payrollPeriod ?? this.payrollPeriod,
      basicSalary: basicSalary ?? this.basicSalary,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      bonusDescription: clearBonusDesc ? null : (bonusDescription ?? this.bonusDescription),
      deductionAmount: deductionAmount ?? this.deductionAmount,
      deductionDescription: clearDeductionDesc ? null : (deductionDescription ?? this.deductionDescription),
      netSalary: netSalary ?? this.netSalary,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'employee_name': employeeName,
    'employee_role': employeeRole,
    'branch_id': branchId,
    'payroll_period': payrollPeriod,
    'basic_salary': basicSalary,
    'bonus_amount': bonusAmount,
    'bonus_description': bonusDescription,
    'deduction_amount': deductionAmount,
    'deduction_description': deductionDescription,
    'net_salary': netSalary,
    'payment_method': paymentMethod.code,
    'payment_date': paymentDate.toIso8601String(),
    'paid_by': paidBy,
    'paid_by_name': paidByName,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Payroll.fromJson(Map<String, dynamic> json) => Payroll(
    id: json['id'] as String,
    employeeId: json['employee_id'] as String,
    employeeName: json['employee_name'] as String? ?? 'ဝန်ထမ်း',
    employeeRole: json['employee_role'] as String? ?? 'Staff',
    branchId: json['branch_id'] as String,
    payrollPeriod: json['payroll_period'] as String,
    basicSalary: (json['basic_salary'] as num).toDouble(),
    bonusAmount: (json['bonus_amount'] as num?)?.toDouble() ?? 0.0,
    bonusDescription: json['bonus_description'] as String?,
    deductionAmount: (json['deduction_amount'] as num?)?.toDouble() ?? 0.0,
    deductionDescription: json['deduction_description'] as String?,
    netSalary: (json['net_salary'] as num).toDouble(),
    paymentMethod: PayrollPaymentMethod.fromCode(json['payment_method'] as String? ?? 'cash'),
    paymentDate: DateTime.parse(json['payment_date'] as String),
    paidBy: json['paid_by'] as String?,
    paidByName: json['paid_by_name'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ── Payrolls (empty — loaded dynamically from GET /api/v1/payrolls) ──────────
const List<Payroll> kBaselinePayrolls = [];

