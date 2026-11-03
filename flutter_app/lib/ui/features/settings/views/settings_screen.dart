import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/receipt_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../pos/view_models/transaction_notifier.dart';
import '../../../shared/dialogs/server_connection_dialog.dart';
import '../view_models/category_notifier.dart';
import '../widgets/branch_management_view.dart';
import '../widgets/category_management_view.dart';
import '../widgets/user_access_management_view.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../../purchases/views/vendor_management_screen.dart';
import '../../../../core/theme/theme_notifier.dart';

enum SettingsTab {
  categories('Categories & Subcategories', '🏷️', 'အမျိုးအစားနှင့် အုပ်စုခွဲများ စီမံခန့်ခွဲမှု'),
  branches('Shop Branches', '🏢', 'ဆိုင်ခွဲများ စီမံခန့်ခွဲမှု'),
  vendors('Vendors & Suppliers', '🤝', 'ကုန်သည်များနှင့် ပစ္စည်းထောက်ပံ့သူများ စီမံခန့်ခွဲမှု'),
  userManagement('User Access & Roles', '👥', 'အသုံးပြုသူနှင့် လုပ်ပိုင်ခွင့် စီမံခန့်ခွဲမှု'),
  printer('Printer & Hardware', '🖨️', 'အပူသုံးပရင်တာနှင့် စက်ကိရိယာများ');

  const SettingsTab(this.title, this.icon, this.burmeseTitle);
  final String title;
  final String icon;
  final String burmeseTitle;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.initialTab});

  final SettingsTab? initialTab;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsTab? _selectedTab;

  late TextEditingController _ipCtrl;
  late TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    final settings = ref.read(transactionProvider).printerSettings;
    _ipCtrl = TextEditingController(text: settings.networkIp);
    _portCtrl = TextEditingController(text: '${settings.networkPort}');
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _selectedTab = widget.initialTab;
      });
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _savePrinterSettings() {
    final current = ref.read(transactionProvider).printerSettings;
    final updated = current.copyWith(
      networkIp: _ipCtrl.text.trim(),
      networkPort: int.tryParse(_portCtrl.text.trim()) ?? 9100,
    );
    ref.read(transactionProvider.notifier).updatePrinterSettings(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hardware and printer settings saved.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _confirmLogout() {
    final user = ref.read(authProvider).currentUser;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'စနစ်မှ ထွက်ခွာမည်လား? (Sign Out)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'လက်ရှိ လော့ဂ်အင်ဝင်ထားသူ: ${user?.name ?? 'Staff'} (${user?.role.label ?? 'Role'}).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'စနစ်မှ ထွက်ခွာပြီး လော့ဂ်အင်စာမျက်နှာသို့ ပြန်လည်ရောက်ရှိပါမည်။',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မထွက်ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ထွက်မည် (Sign Out)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode != ThemeMode.light;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ── Top Header Bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_selectedTab == null) ...[
                  // Overview Default Header
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System & Terminal Settings',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'စနစ်နှင့် ဆက်တင်များ စီမံခန့်ခွဲမှုဗဟို (Settings Hub)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                ] else ...[
                  // Sub-screen Header with Back Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = null),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'ဆက်တင်များ (Settings)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 24, color: AppColors.border),
                  const SizedBox(width: 14),

                  // Current Selected Tab Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_selectedTab!.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTab!.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedTab!.burmeseTitle,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Tab Switcher for Quick Jump
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: SettingsTab.values.map((tab) {
                            final isSelected = _selectedTab == tab;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTab = tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Text(tab.icon, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(
                                      tab.title.split(' & ').first,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // Tab specific action for printer
                  if (_selectedTab == SettingsTab.printer) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _savePrinterSettings,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],

                // Theme Mode Switch (Dark / White theme quick switch)
                const SizedBox(width: 12),
                Tooltip(
                  message: isDark
                      ? 'Switch to White Theme (အလင်းစနစ်သို့ ပြောင်းရန်)'
                      : 'Switch to Dark Theme (အမှောင်စနစ်သို့ ပြောင်းရန်)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                : AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? const Color(0xFFF59E0B) : AppColors.primary,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),

                // Logout Action inside Setting (compact icon button)
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Sign Out / Lock (အကောင့်ထွက်မည်)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _confirmLogout,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content Area ─────────────────────────────────
          Expanded(
            child: _selectedTab == null
                ? _buildSettingsOverviewGrid(context, isDark)
                : switch (_selectedTab!) {
                    SettingsTab.categories => const CategoryManagementView(),
                    SettingsTab.branches => const BranchManagementView(),
                    SettingsTab.vendors => const VendorManagementScreen(isEmbedded: true),
                    SettingsTab.userManagement => const UserAccessManagementView(),
                    SettingsTab.printer => _buildPrinterSettingsContent(),
                  },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETTINGS DEFAULT GRID OVERVIEW
  // ============================================================
  Widget _buildSettingsOverviewGrid(BuildContext context, bool isDark) {
    final categories = ref.watch(categoryNotifierProvider);
    final branches = ref.watch(branchListNotifierProvider);
    final vendors = ref.watch(vendorProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.currentUser;
    final totalUsers = authState.users.length;
    final printerSettings = ref.watch(transactionProvider).printerSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'စနစ်နှင့် ဆက်တင်များ ရွေးချယ်ခန့်ခွဲမှု (Settings Menu)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'အောက်ပါ ကဏ္ဍများထဲမှ ပြင်ဆင်လိုသည့် Settings Card ကို နှိပ်၍ သက်ဆိုင်ရာ စာမျက်နှာသို့ သွားရောက်စီမံနိုင်ပါသည်။',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cards Grid
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 540,
              mainAxisExtent: 140,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            children: [
              _buildGridCard(
                iconEmoji: '🏷️',
                title: 'Categories & Subcategories',
                burmeseTitle: 'အမျိုးအစားနှင့် အုပ်စုခွဲများ စီမံခန့်ခွဲမှု',
                description: 'ကုန်ပစ္စည်း အမျိုးအစားများ၊ အုပ်စုခွဲများနှင့် ရောင်းချမှုအုပ်စုများ သတ်မှတ်စီမံခြင်း',
                accentColor: const Color(0xFF10B981),
                badgeText: '${categories.length} Categories',
                onTap: () => setState(() => _selectedTab = SettingsTab.categories),
              ),
              _buildGridCard(
                iconEmoji: '🏢',
                title: 'Shop Branches',
                burmeseTitle: 'ဆိုင်ခွဲများ စီမံခန့်ခွဲမှု (Branches)',
                description: 'ဆိုင်ခွဲသစ်များ ဖွင့်လှစ်ခြင်း၊ လိပ်စာ၊ ဖုန်းနံပါတ်နှင့် ဆိုင်ခွဲအခြေအနေများ စီမံခြင်း',
                accentColor: const Color(0xFF3B82F6),
                badgeText: '${branches.length} Branches',
                onTap: () => setState(() => _selectedTab = SettingsTab.branches),
              ),
              _buildGridCard(
                iconEmoji: '🤝',
                title: 'Vendors & Suppliers',
                burmeseTitle: 'ကုန်သည်များနှင့် ပစ္စည်းထောက်ပံ့သူများ စီမံခန့်ခွဲမှု',
                description: 'ပစ္စည်းသွင်းသူ ကုန်သည်စာရင်း၊ ပေးရန်ကျန်ငွေနှင့် အဆက်အသွယ်များ စီမံခန့်ခွဲခြင်း',
                accentColor: const Color(0xFFF59E0B),
                badgeText: '${vendors.length} Vendors',
                onTap: () => setState(() => _selectedTab = SettingsTab.vendors),
              ),
              _buildGridCard(
                iconEmoji: '👥',
                title: 'User Access & Roles',
                burmeseTitle: 'အသုံးပြုသူနှင့် လုပ်ပိုင်ခွင့် စီမံခန့်ခွဲမှု',
                description: 'ဝန်ထမ်းအကောင့်များ၊ ရာထူးများနှင့် ဘယ်ဘက် Menu သုံးစွဲခွင့် အုပ်စုများ သတ်မှတ်ခြင်း',
                accentColor: const Color(0xFF06B6D4),
                badgeText: '$totalUsers Accounts',
                onTap: () => setState(() => _selectedTab = SettingsTab.userManagement),
              ),
              _buildGridCard(
                iconEmoji: '🖨️',
                title: 'Printer & Hardware',
                burmeseTitle: 'အပူသုံးပရင်တာနှင့် စက်ကိရိယာများ',
                description: 'ဘောက်ချာထုတ် ပရင်တာ IP (${printerSettings.networkIp})၊ Port (${printerSettings.networkPort}) နှင့် POS စက်များ',
                accentColor: const Color(0xFF8B5CF6),
                badgeText: '${printerSettings.networkIp}:${printerSettings.networkPort}',
                onTap: () => setState(() => _selectedTab = SettingsTab.printer),
              ),
              _buildGridCard(
                iconEmoji: '☁️',
                title: 'Cloud Server & Database',
                burmeseTitle: 'Cloud ဆာဗာနှင့် PostgreSQL ချိတ်ဆက်မှု',
                description: 'ဗဟို Cloud API URL ပြောင်းလဲခြင်း၊ ချိတ်ဆက်မှု Ping စစ်ဆေးခြင်းနှင့် ဆာဗာ အခြေအနေ',
                accentColor: const Color(0xFF6366F1),
                badgeText: Uri.tryParse(AppConstants.apiBaseUrl)?.host ?? 'Cloud API',
                onTap: () => ServerConnectionDialog.show(context),
              ),
              _buildThemeGridCard(isDark),
              _buildGridCard(
                iconEmoji: '🚪',
                title: 'Sign Out / Switch Account',
                burmeseTitle: 'စနစ်မှ ထွက်ခွာခြင်း (လော့ဂ်အောက်)',
                description: 'လက်ရှိဝင်ထားသူ: ${currentUser?.name ?? 'Staff'} (${currentUser?.role.label ?? 'Role'})',
                accentColor: AppColors.error,
                badgeText: 'Sign Out',
                isDestructive: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGridCard(bool isDark) {
    final accent = isDark ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
        borderRadius: BorderRadius.circular(16),
        hoverColor: accent.withValues(alpha: 0.05),
        splashColor: accent.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isDark ? 'Theme: Dark Forest' : 'Theme: Clean White',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isDark ? 'Dark Mode' : 'White Theme',
                            style: TextStyle(
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isDark
                          ? 'အလင်းစနစ် (White Theme) သို့ ပြောင်းရန် နှိပ်ပါ'
                          : 'အမှောင်စနစ် (Dark Mode) သို့ ပြောင်းရန် နှိပ်ပါ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark
                          ? 'စနစ်တစ်ခုလုံးကို အဖြူရောင်နောက်ခံနှင့် လင်းထင်းရှင်းလင်းသော အသွင်အပြင်သို့ ပြောင်းလဲမည်'
                          : 'စနစ်တစ်ခုလုံးကို မူလမျက်စိအေးချမ်းသော တောအုပ်အစိမ်းရင့် အမှောင်စနစ်သို့ ပြောင်းလဲမည်',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: !isDark,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF8BB89A),
                inactiveTrackColor: AppColors.surfaceVariant,
                onChanged: (_) => ref.read(themeNotifierProvider.notifier).toggleTheme(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String iconEmoji,
    required String title,
    required String burmeseTitle,
    required String description,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: accentColor.withValues(alpha: 0.05),
        splashColor: accentColor.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  iconEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isDestructive ? AppColors.error : AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      burmeseTitle,
                      style: TextStyle(
                        color: isDestructive ? AppColors.error.withValues(alpha: 0.9) : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRINTER SETTINGS VIEW
  // ============================================================
  Widget _buildPrinterSettingsContent() {
    final settings = ref.watch(transactionProvider).printerSettings;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ESC/POS Printer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESC/POS Thermal Receipt Printer',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipCtrl,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Network IP Address (LAN)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _portCtrl,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Port (Default: 9100)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Default Paper Size: ', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 10),
                  SegmentedButton<ReceiptPaperSize>(
                    segments: const [
                      ButtonSegment(value: ReceiptPaperSize.mm80, label: Text('80mm (~48 col)')),
                      ButtonSegment(value: ReceiptPaperSize.mm58, label: Text('58mm (~32 col)')),
                    ],
                    selected: {settings.paperSize},
                    onSelectionChanged: (set) {
                      final updated = settings.copyWith(paperSize: set.first);
                      ref.read(transactionProvider.notifier).updatePrinterSettings(updated);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Shop & Multi-Branch Overview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SitePyoe Nursery & Garden Centers',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Branch 1: SitePyoe Branch A (Mingaladon Nursery & Greenhouse)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Branch 2: SitePyoe Branch B (Hledan Garden Center)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
