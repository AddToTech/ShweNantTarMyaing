import 'app_permission.dart';
import '../mock/mock_products.dart';

enum UserRole {
  owner(
    code: 'owner',
    label: 'Super Admin / Owner',
    burmeseLabel: 'စူပါအက်ဒမင် / ပိုင်ရှင်',
    icon: '👑',
    description: 'Full access to all branches, financial reports, user management, and system settings.',
  ),
  manager(
    code: 'manager',
    label: 'Branch Manager',
    burmeseLabel: 'ဆိုင်ခွဲမန်နေဂျာ',
    icon: '🏢',
    description: 'Can manage inventory, transfers, view branch sales reports, and log wastage.',
  ),
  cashier(
    code: 'cashier',
    label: 'Cashier',
    burmeseLabel: 'ငွေကိုင်',
    icon: '💵',
    description: 'Standard POS checkout, cart operations, customer receipts, and cash drawer.',
  ),
  stockClerk(
    code: 'stock_clerk',
    label: 'Stock Clerk',
    burmeseLabel: 'ပစ္စည်းထိန်း',
    icon: '📦',
    description: 'Can update stock counts, receive branch transfers, and log plant mortality/damage.',
  );

  const UserRole({
    required this.code,
    required this.label,
    required this.burmeseLabel,
    required this.icon,
    required this.description,
  });

  final String code;
  final String label;
  final String burmeseLabel;
  final String icon;
  final String description;
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? permissionGroupId; // Linked PermissionGroup ID
  final List<AppMenuPermission>? customPermissions; // Optional custom overrides
  final String? branchId; // null = all branches, 'branch_a', 'branch_b'
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.permissionGroupId,
    this.customPermissions,
    this.branchId,
    this.phone,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?)?.toLowerCase() ?? 'cashier';
    final parsedRole = UserRole.values.firstWhere(
      (r) => r.code.toLowerCase() == roleStr || r.name.toLowerCase() == roleStr,
      orElse: () => UserRole.cashier,
    );

    final rawBranchId = json['branch_id']?.toString() ?? json['branchId']?.toString();
    final rawBranchName = json['branch_name']?.toString() ?? json['branchName']?.toString();
    final normalizedBranchId = (rawBranchId != null && rawBranchId.isNotEmpty)
        ? normalizeBranchId(rawBranchId, branchName: rawBranchName)
        : null;

    final rawGroupId =
        json['permission_group_id']?.toString() ?? json['permissionGroupId']?.toString();
    final defaultGroupId = switch (parsedRole) {
      UserRole.owner => 'pg_owner',
      UserRole.manager => 'pg_manager',
      UserRole.stockClerk => 'pg_stock',
      UserRole.cashier => 'pg_cashier',
    };

    final rawCustomPerms = json['custom_permissions'] ?? json['customPermissions'];
    List<AppMenuPermission>? parsedCustomPerms;
    if (rawCustomPerms is List && rawCustomPerms.isNotEmpty) {
      parsedCustomPerms = rawCustomPerms
          .map((e) => AppMenuPermission.fromCode(e.toString()))
          .whereType<AppMenuPermission>()
          .toList();
    }

    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: '', // Never stored in plain text from API
      role: parsedRole,
      permissionGroupId:
          (rawGroupId != null && rawGroupId.isNotEmpty) ? rawGroupId : defaultGroupId,
      customPermissions: parsedCustomPerms,
      branchId: normalizedBranchId,
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['isActive'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'].toString())
          : (json['lastLoginAt'] != null
              ? DateTime.tryParse(json['lastLoginAt'].toString())
              : null),
    );
  }

  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager || isOwner;
  bool get canManageUsers => isOwner;
  bool get canViewReports => isManager;

  /// Returns effective allowed Left Side Menu items for this user
  List<AppMenuPermission> getAllowedMenus(List<PermissionGroup> groups) {
    if (customPermissions != null && customPermissions!.isNotEmpty) {
      return customPermissions!;
    }
    if (permissionGroupId != null) {
      final grp = groups.where((g) => g.id == permissionGroupId).firstOrNull;
      if (grp != null) return grp.permissions;
    }
    // Fallback based on UserRole
    return switch (role) {
      UserRole.owner => AppMenuPermission.values,
      UserRole.manager => const [
          AppMenuPermission.pos,
          AppMenuPermission.orders,
          AppMenuPermission.stock,
          AppMenuPermission.transfer,
          AppMenuPermission.wastage,
          AppMenuPermission.reports,
          AppMenuPermission.purchases,
          AppMenuPermission.hr,
        ],
      UserRole.cashier => const [
          AppMenuPermission.pos,
          AppMenuPermission.orders,
        ],
      UserRole.stockClerk => const [
          AppMenuPermission.stock,
          AppMenuPermission.transfer,
          AppMenuPermission.wastage,
        ],
    };
  }

  /// Whether user has access to a specific left menu
  bool hasMenuPermission(AppMenuPermission perm, List<PermissionGroup> groups) {
    return getAllowedMenus(groups).contains(perm);
  }

  /// Whether user has permission to delete data/records (products, orders/vouchers, financial records)
  /// Super Admin / Owner always has permission. Staff members require dynamic permission.
  bool canDeleteData(List<PermissionGroup> groups) {
    if (isOwner) return true;
    return getAllowedMenus(groups).contains(AppMenuPermission.deleteData);
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    UserRole? role,
    String? permissionGroupId,
    bool clearPermissionGroup = false,
    List<AppMenuPermission>? customPermissions,
    bool clearCustomPermissions = false,
    String? branchId,
    bool clearBranch = false,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      permissionGroupId: clearPermissionGroup
          ? null
          : (permissionGroupId ?? this.permissionGroupId),
      customPermissions: clearCustomPermissions
          ? null
          : (customPermissions ?? this.customPermissions),
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.code,
      'permission_group_id': permissionGroupId,
      'custom_permissions': customPermissions?.map((p) => p.code).toList(),
      'branch_id': branchId,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}
