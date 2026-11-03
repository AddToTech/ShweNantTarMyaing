import 'package:flutter/material.dart';

// ============================================================
// Left Side Menu Permission Enum
// Each enum value strictly corresponds to an item in the Side Navigation Rail
// ============================================================

enum AppMenuPermission {
  pos(
    code: 'pos',
    label: 'POS & Sales',
    burmeseLabel: 'အရောင်း / POS',
    icon: Icons.point_of_sale_rounded,
    outlineIcon: Icons.point_of_sale_outlined,
    navIndex: 0,
    emoji: '🛒',
    description: 'အရောင်းကောင်တာ၊ စျေးခြင်းတောင်း၊ ဘားကုဒ်စကင်နှင့် ငွေရှင်းဘောက်ချာ ထုတ်ပေးခြင်း',
  ),
  orders(
    code: 'orders',
    label: 'Order History',
    burmeseLabel: 'ဘောက်ချာ / Orders',
    icon: Icons.receipt_long_rounded,
    outlineIcon: Icons.receipt_long_outlined,
    navIndex: 1,
    emoji: '🧾',
    description: 'ယခင်ရောင်းချခဲ့သော ဘောက်ချာစာရင်းများ ပြန်လည်ကြည့်ရှုခြင်းနှင့် ပြေစာပြန်လည်ထုတ်ပေးခြင်း',
  ),
  stock(
    code: 'stock',
    label: 'Inventory & Stock',
    burmeseLabel: 'ပစ္စည်းစာရင်း / Stock',
    icon: Icons.inventory_2_rounded,
    outlineIcon: Icons.inventory_2_outlined,
    navIndex: 2,
    emoji: '📦',
    description: 'အပင်နှင့် ပစ္စည်းလက်ကျန် စစ်ဆေးခြင်း၊ ကုန်ပစ္စည်းအသစ် ထည့်သွင်း/ပြင်ဆင်ခြင်း',
  ),
  transfer(
    code: 'transfer',
    label: 'Stock Transfer',
    burmeseLabel: 'လွှဲပြောင်း / Transfer',
    icon: Icons.swap_horiz_rounded,
    outlineIcon: Icons.swap_horiz_outlined,
    navIndex: 3,
    emoji: '🔄',
    description: 'ဆိုင်ခွဲများအချင်းချင်း ကုန်ပစ္စည်းနှင့် အပင်များ လွှဲပြောင်းပေးပို့ခြင်းနှင့် လက်ခံခြင်း',
  ),
  wastage(
    code: 'wastage',
    label: 'Wastage & Loss',
    burmeseLabel: 'ပျက်စီး/သေ / Wastage',
    icon: Icons.eco_rounded,
    outlineIcon: Icons.eco_outlined,
    navIndex: 4,
    emoji: '🥀',
    description: 'အပင်သေဆုံးပျက်စီးမှု၊ ညှိုးနွမ်းမှုနှင့် ဆုံးရှုံးမှုတန်ဖိုးများ မှတ်တမ်းတင်ခြင်း',
  ),
  reports(
    code: 'reports',
    label: 'Reports & Analytics',
    burmeseLabel: 'အစီရင်ခံစာ / Reports',
    icon: Icons.bar_chart_rounded,
    outlineIcon: Icons.bar_chart_outlined,
    navIndex: 5,
    emoji: '📊',
    description: 'အရောင်းစာရင်း၊ ကုန်ပစ္စည်းအရောင်း၊ သိုလှောင်ရုံတန်ဖိုးနှင့် အကြွေးစာရင်း အစီရင်ခံစာများ',
  ),
  settings(
    code: 'settings',
    label: 'System Settings',
    burmeseLabel: 'ဆက်တင် / Settings',
    icon: Icons.settings_rounded,
    outlineIcon: Icons.settings_outlined,
    navIndex: 6,
    emoji: '⚙️',
    description: 'အမျိုးအစားနှင့် အုပ်စုခွဲ CRUD၊ ဝန်ထမ်းလုပ်ပိုင်ခွင့်နှင့် ပရင်တာချိတ်ဆက်မှုများ',
  ),
  purchases(
    code: 'purchases',
    label: 'Purchases / Stock-In',
    burmeseLabel: 'အဝယ်စာရင်း / Purchases',
    icon: Icons.shopping_cart_checkout_rounded,
    outlineIcon: Icons.shopping_cart_checkout_outlined,
    navIndex: 7,
    emoji: '📥',
    description: 'ကုန်သည်များထံမှ ပစ္စည်းဝယ်ယူခြင်း၊ ပြေစာမှတ်တမ်းနှင့် ဘဏ္ဍာရေးပေးချေမှုစာရင်း',
  ),
  hr(
    code: 'hr',
    label: 'HR & Payroll',
    burmeseLabel: 'ဝန်ထမ်းနှင့် လစာ / HR',
    icon: Icons.badge_rounded,
    outlineIcon: Icons.badge_outlined,
    navIndex: 8,
    emoji: '👥',
    description: 'ဝန်ထမ်းစာရင်းများ စီမံခန့်ခွဲခြင်း (CRUD)၊ လစာနှင့် ချီးမြှင့်ငွေ/ဒဏ်ကြေး ရှင်းတမ်း ထုတ်ပေးခြင်း',
  ),
  deleteData(
    code: 'delete_data',
    label: 'Delete Data & Records',
    burmeseLabel: 'အချက်အလက်/ဘောက်ချာ ဖျက်ခွင့် (Delete)',
    icon: Icons.delete_forever_rounded,
    outlineIcon: Icons.delete_forever_outlined,
    navIndex: -1,
    emoji: '🗑️',
    description: 'ကုန်ပစ္စည်း၊ အရောင်းဘောက်ချာနှင့် ဘဏ္ဍာရေးစာရင်းမှတ်တမ်းများ ပယ်ဖျက်ခွင့်',
  );

  const AppMenuPermission({
    required this.code,
    required this.label,
    required this.burmeseLabel,
    required this.icon,
    required this.outlineIcon,
    required this.navIndex,
    required this.emoji,
    required this.description,
  });

  final String code;
  final String label;
  final String burmeseLabel;
  final IconData icon;
  final IconData outlineIcon;
  final int navIndex;
  final String emoji;
  final String description;

  /// Whether this permission corresponds to an item in the main Left Side Navigation Rail
  bool get isMenu => navIndex >= 0;

  static AppMenuPermission? fromCode(String code) {
    for (final p in AppMenuPermission.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

// ============================================================
// Permission Group Model
// Bundles left-side menu permissions into named profiles
// ============================================================

class PermissionGroup {
  final String id;
  final String name;
  final String burmeseName;
  final String description;
  final String icon;
  final List<AppMenuPermission> permissions;
  final bool isBuiltIn;

  const PermissionGroup({
    required this.id,
    required this.name,
    required this.burmeseName,
    required this.description,
    required this.icon,
    required this.permissions,
    this.isBuiltIn = false,
  });

  bool hasPermission(AppMenuPermission perm) => permissions.contains(perm);

  PermissionGroup copyWith({
    String? id,
    String? name,
    String? burmeseName,
    String? description,
    String? icon,
    List<AppMenuPermission>? permissions,
    bool? isBuiltIn,
  }) {
    return PermissionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      burmeseName: burmeseName ?? this.burmeseName,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      permissions: permissions ?? this.permissions,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'burmeseName': burmeseName,
    'description': description,
    'icon': icon,
    'permissions': permissions.map((p) => p.code).toList(),
    'isBuiltIn': isBuiltIn,
  };

  factory PermissionGroup.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final List<AppMenuPermission> parsedPerms = [];
    if (rawPerms is List) {
      for (final item in rawPerms) {
        final p = AppMenuPermission.fromCode(item.toString());
        if (p != null) parsedPerms.add(p);
      }
    }
    return PermissionGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      burmeseName:
          json['burmese_name']?.toString() ?? json['burmeseName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🛡️',
      permissions: parsedPerms,
      isBuiltIn: json['is_built_in'] == true || json['isBuiltIn'] == true,
    );
  }
}

// ============================================================
// Default Built-in Permission Groups
// ============================================================

const List<PermissionGroup> kDefaultPermissionGroups = [];
