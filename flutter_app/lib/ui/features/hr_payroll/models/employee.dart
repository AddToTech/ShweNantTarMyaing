// ============================================================
// Employee Domain Model
// Represents staff members in SitePyoe Nursery POS System
// ============================================================

enum EmployeeRole {
  manager(code: 'Manager', burmeseLabel: 'ဆိုင်ခွဲမန်နေဂျာ (Manager)'),
  cashier(code: 'Cashier', burmeseLabel: 'ငွေကိုင် / အရောင်း (Cashier)'),
  gardener(code: 'Gardener', burmeseLabel: 'ဥယျာဉ်မှူး / အပင်ထိန်း (Gardener)'),
  delivery(code: 'Delivery', burmeseLabel: 'ပို့ဆောင်ရေး (Delivery Driver)'),
  florist(code: 'Florist', burmeseLabel: 'ပန်းအလှဆင်ကျွမ်းကျင် (Florist)'),
  general(code: 'General', burmeseLabel: 'အထွေထွေ အကူ (General Staff)');

  const EmployeeRole({required this.code, required this.burmeseLabel});
  final String code;
  final String burmeseLabel;

  String get label => burmeseLabel;

  static EmployeeRole fromCode(String code) {
    for (final r in EmployeeRole.values) {
      if (r.code.toLowerCase() == code.toLowerCase()) return r;
    }
    return EmployeeRole.general;
  }
}

class Employee {
  const Employee({
    required this.id,
    required this.branchId,
    required this.name,
    required this.role,
    this.phone,
    this.address,
    required this.basicSalary,
    required this.joinDate,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String branchId;
  final String name;
  final String role; // Can use EmployeeRole code or custom role string
  final String? phone;
  final String? address;
  final double basicSalary;
  final DateTime joinDate;
  final bool isActive;
  final DateTime createdAt;

  Employee copyWith({
    String? branchId,
    String? name,
    String? role,
    String? phone,
    bool clearPhone = false,
    String? address,
    bool clearAddress = false,
    double? basicSalary,
    DateTime? joinDate,
    bool? isActive,
  }) {
    return Employee(
      id: id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: clearPhone ? null : (phone ?? this.phone),
      address: clearAddress ? null : (address ?? this.address),
      basicSalary: basicSalary ?? this.basicSalary,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'name': name,
    'role': role,
    'phone': phone,
    'address': address,
    'basic_salary': basicSalary,
    'join_date': joinDate.toIso8601String(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    branchId: json['branch_id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    basicSalary: (json['basic_salary'] as num).toDouble(),
    joinDate: DateTime.parse(json['join_date'] as String),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ── Employees (empty — loaded dynamically from GET /api/v1/employees) ────────
const List<Employee> kBaselineEmployees = [];

