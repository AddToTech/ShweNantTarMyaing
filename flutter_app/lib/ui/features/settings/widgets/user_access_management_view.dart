import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/models/app_permission.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../view_models/permission_group_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

// ============================================================
// Sub-tabs for User Access & Roles View
// ============================================================

enum UserSubTab {
  users('Staff Accounts', '👥', 'ဝန်ထမ်းစာရင်းနှင့် လုပ်ပိုင်ခွင့်များ'),
  permissionGroups('Permission Groups', '🛡️', 'ဘယ်ဘက် Menu သုံးစွဲခွင့် အုပ်စုများ');

  const UserSubTab(this.title, this.icon, this.burmeseTitle);
  final String title;
  final String icon;
  final String burmeseTitle;
}

// ============================================================
// User Access & Permission Groups Management View
// ============================================================

class UserAccessManagementView extends ConsumerStatefulWidget {
  const UserAccessManagementView({super.key});

  @override
  ConsumerState<UserAccessManagementView> createState() =>
      _UserAccessManagementViewState();
}

class _UserAccessManagementViewState
    extends ConsumerState<UserAccessManagementView> {
  UserSubTab _currentSubTab = UserSubTab.users;
  final _searchUserCtrl = TextEditingController();
  final _searchGroupCtrl = TextEditingController();
  UserRole? _selectedRoleFilter;
  String? _selectedGroupFilter;

  @override
  void dispose() {
    _searchUserCtrl.dispose();
    _searchGroupCtrl.dispose();
    super.dispose();
  }

  void _showAddEditUserDialog({AppUser? user}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditUserDialog(userToEdit: user),
    );
  }

  void _confirmDeleteUser(AppUser user) {
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
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete User Account?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${user.name}" (${user.email})? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final err = await ref.read(authProvider.notifier).deleteUser(user.id);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted account "${user.name}" successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showAddEditGroupDialog({PermissionGroup? group}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditPermissionGroupDialog(groupToEdit: group),
    );
  }

  void _confirmDeleteGroup(PermissionGroup group) {
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
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Permission Group ဖျက်မလား?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Permission Group "${group.name}" (${group.burmeseName}) ကို ဖျက်ရန် သေချာပါသလား?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final err = await ref
                  .read(permissionGroupProvider.notifier)
                  .deleteGroup(group.id);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Deleted group "${group.name}" successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
  }

  void _confirmResetGroupsDefaults() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restore_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Text('မူလ Permission Groups ပြန်ထားမလား?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Text(
          'Permission Groups စာရင်းကို မူလစနစ်သတ်မှတ်ချက်များ (Super Admin, Branch Manager, Cashier, Stock Clerk) အတိုင်း ပြန်လည်ထားရှိပါမည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(permissionGroupProvider.notifier).resetToDefaults();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('မူလ Permission Groups အတိုင်း ပြန်ထားပြီးပါပြီ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            child: const Text('မူလအတိုင်း ပြန်ထားမည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final permissionGroups = ref.watch(permissionGroupProvider);
    final isSuperAdmin = authState.currentUser?.role == UserRole.owner;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Sub-Tab Switcher & Top Action Button ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Sub-tab switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: UserSubTab.values.map((tab) {
                      final isSel = _currentSubTab == tab;
                      return GestureDetector(
                        onTap: () => setState(() => _currentSubTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(tab.icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Text(
                                tab.title,
                                style: TextStyle(
                                  color: isSel
                                      ? AppColors.textOnPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tab == UserSubTab.users
                                      ? '${authState.users.length}'
                                      : '${permissionGroups.length}',
                                  style: TextStyle(
                                    color: isSel
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Spacer(),

                // Contextual Action Button
                if (isSuperAdmin) ...[
                  if (_currentSubTab == UserSubTab.users)
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditUserDialog(),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 17),
                      label: const Text(
                        '+ Add New User (အသုံးပြုသူအသစ်)',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.restore_rounded,
                              size: 19, color: AppColors.textMuted),
                          tooltip: 'မူလ Permission Groups အတိုင်း ပြန်ထားမည်',
                          onPressed: _confirmResetGroupsDefaults,
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditGroupDialog(),
                          icon: const Icon(Icons.add_moderator_rounded,
                              size: 17),
                          label: const Text(
                            '+ Add Permission Group (လုပ်ပိုင်ခွင့်အုပ်စု အသစ်)',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Main Body Switcher ──────────────────────────────────
          Expanded(
            child: _currentSubTab == UserSubTab.users
                ? _buildUsersTabContent(authState, permissionGroups, isSuperAdmin)
                : _buildPermissionGroupsTabContent(
                    permissionGroups, authState, isSuperAdmin),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: USERS LIST & PERMISSION BADGES
  // ============================================================

  Widget _buildUsersTabContent(
    AuthState authState,
    List<PermissionGroup> permissionGroups,
    bool isSuperAdmin,
  ) {
    final query = _searchUserCtrl.text.trim().toLowerCase();

    final filteredUsers = authState.users.where((u) {
      if (_selectedRoleFilter != null && u.role != _selectedRoleFilter) {
        return false;
      }
      if (_selectedGroupFilter != null &&
          u.permissionGroupId != _selectedGroupFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final match = u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.phone != null && u.phone!.contains(query));
        if (!match) return false;
      }
      return true;
    }).toList();

    final totalUsers = authState.users.length;
    final ownerCount =
        authState.users.where((u) => u.role == UserRole.owner).length;
    final managerCount =
        authState.users.where((u) => u.role == UserRole.manager).length;
    final cashierCount =
        authState.users.where((u) => u.role == UserRole.cashier).length;

    return Column(
      children: [
        // Role Metric Cards
        Row(
          children: [
            _buildMetricCard(
              icon: '👥',
              title: 'Total Accounts',
              burmese: 'အသုံးပြုသူ စုစုပေါင်း',
              count: '$totalUsers Staff',
              color: AppColors.primary,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '👑',
              title: 'Super Admins',
              burmese: 'စူပါအက်ဒမင် (ပိုင်ရှင်)',
              count: '$ownerCount Accounts',
              color: Colors.amber,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '🏢',
              title: 'Branch Managers',
              burmese: 'ဆိုင်ခွဲမန်နေဂျာများ',
              count: '$managerCount Accounts',
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '💵',
              title: 'Cashiers & Clerks',
              burmese: 'ငွေကိုင် / အရောင်းဝန်ထမ်း',
              count: '$cashierCount Accounts',
              color: AppColors.success,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Filter Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Search box
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchUserCtrl,
                    onChanged: (_) => setState(() {}),
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'အမည်၊ အီးမေးလ် သို့မဟုတ် ဖုန်းနံပါတ် ရှာဖွေပါ...',
                      hintStyle:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchUserCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () =>
                                  setState(() => _searchUserCtrl.clear()),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textMuted),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Role filter chips
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('ရာထူးအားလုံး (All Roles)',
                              style: TextStyle(fontSize: 11)),
                          selected: _selectedRoleFilter == null,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceVariant,
                          onSelected: (_) =>
                              setState(() => _selectedRoleFilter = null),
                        ),
                      ),
                      ...UserRole.values.map((role) {
                        final selected = _selectedRoleFilter == role;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(role.icon,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  role.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceVariant,
                            onSelected: (_) =>
                                setState(() => _selectedRoleFilter = role),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Users List with Menu Badges
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(authProvider.notifier).loadRemoteUsers(),
                ref.read(permissionGroupProvider.notifier).loadGroups(),
              ]);
            },
            child: authState.isLoading && filteredUsers.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'အသုံးပြုသူ ဝန်ထမ်းစာရင်းများ ရယူနေပါသည်...',
                      subMessage: 'Loading staff accounts...',
                      icon: Icons.people_alt_rounded,
                    ),
                  )
                : filteredUsers.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('ရှာဖွေမှုနှင့် ကိုက်ညီသော အကောင့်မရှိပါ',
                              style:
                                  TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                    final u = filteredUsers[index];
                    final isCurrentActiveUser =
                        authState.currentUser?.id == u.id;
                    final branchLabel = u.branchId != null
                        ? (kBranches[u.branchId] ?? u.branchId!)
                        : 'All Branches (ဆိုင်ခွဲအားလုံး)';

                    // Look up assigned permission group
                    final assignedGroup = permissionGroups
                        .where((g) => g.id == u.permissionGroupId)
                        .firstOrNull;

                    // Compute allowed Left Side Menus
                    final allowedMenus =
                        u.getAllowedMenus(permissionGroups);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrentActiveUser
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.border,
                          width: isCurrentActiveUser ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar with role icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Text(u.role.icon,
                                    style: const TextStyle(fontSize: 20)),
                              ),

                              const SizedBox(width: 14),

                              // Name & contact
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          u.name,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (isCurrentActiveUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'YOU (လက်ရှိဝင်ထားသူ)',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${u.email}  •  ${u.phone ?? 'No phone'}',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),

                              // Role Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      u.role.label,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      u.role.burmeseLabel,
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Permission Group Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(assignedGroup?.icon ?? '🛡️',
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          assignedGroup?.name ?? 'Standard Role',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          assignedGroup?.burmeseName ??
                                              'လုပ်ပိုင်ခွင့်အုပ်စု',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Branch Assignment Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.storefront_outlined,
                                        size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      branchLabel,
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Active Toggle
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch.adaptive(
                                    value: u.isActive,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: isSuperAdmin
                                        ? (v) async {
                                            final err = await ref
                                                .read(authProvider.notifier)
                                                .toggleUserStatus(u.id);
                                            if (err != null && context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(err),
                                                    backgroundColor:
                                                        AppColors.warning),
                                              );
                                            }
                                          }
                                        : null,
                                  ),
                                  Text(
                                    u.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: u.isActive
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 10),

                              // Actions
                              if (isSuperAdmin) ...[
                                IconButton(
                                  icon: Icon(Icons.edit_outlined,
                                      size: 17, color: AppColors.textSecondary),
                                  tooltip: 'Edit user & permissions',
                                  onPressed: () =>
                                      _showAddEditUserDialog(user: u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 17, color: AppColors.error),
                                  tooltip: 'Delete user',
                                  onPressed: isCurrentActiveUser
                                      ? null
                                      : () => _confirmDeleteUser(u),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Left Side Menu Permissions Badges Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'ဘယ်ဘက် Menu သုံးစွဲခွင့်များ: ',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: AppMenuPermission.values.map((perm) {
                                      final isGranted =
                                          allowedMenus.contains(perm);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isGranted
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.16)
                                              : AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isGranted
                                                ? AppColors.primary
                                                    .withValues(alpha: 0.4)
                                                : AppColors.border
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              perm.emoji,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isGranted
                                                    ? null
                                                    : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              perm.burmeseLabel,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isGranted
                                                    ? AppColors.textPrimary
                                                    : AppColors.textMuted,
                                                fontWeight: isGranted
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                decoration: isGranted
                                                    ? null
                                                    : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
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

  // ============================================================
  // TAB 2: PERMISSION GROUPS MANAGEMENT
  // ============================================================

  Widget _buildPermissionGroupsTabContent(
    List<PermissionGroup> permissionGroups,
    AuthState authState,
    bool isSuperAdmin,
  ) {
    final query = _searchGroupCtrl.text.trim().toLowerCase();
    final filteredGroups = permissionGroups.where((g) {
      if (query.isEmpty) return true;
      return g.name.toLowerCase().contains(query) ||
          g.burmeseName.toLowerCase().contains(query) ||
          g.description.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Top Metric Cards for Groups
        Row(
          children: [
            _buildMetricCard(
              icon: '🛡️',
              title: 'Total Permission Groups',
              burmese: 'လုပ်ပိုင်ခွင့်အုပ်စု စုစုပေါင်း',
              count: '${permissionGroups.length} Groups',
              color: AppColors.primary,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '👑',
              title: 'Full Access (All 7 Menus)',
              burmese: 'မီနူးအားလုံး သုံးစွဲခွင့်ရှိသူ',
              count:
                  '${permissionGroups.where((g) => g.permissions.length == 7).length} Groups',
              color: Colors.amber,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '🏢',
              title: 'Branch Operations',
              burmese: 'အရောင်းနှင့် ဆိုင်တွင်းစီမံခွင့်',
              count:
                  '${permissionGroups.where((g) => g.permissions.contains(AppMenuPermission.pos)).length} Groups',
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(width: 14),
            _buildMetricCard(
              icon: '⚙️',
              title: 'Custom User Profiles',
              burmese: 'စိတ်ကြိုက်သတ်မှတ်ထားသောအုပ်စု',
              count:
                  '${permissionGroups.where((g) => !g.isBuiltIn).length} Custom',
              color: AppColors.success,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Filter / Search Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchGroupCtrl,
                    onChanged: (_) => setState(() {}),
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'လုပ်ပိုင်ခွင့်အုပ်စု အမည်ဖြင့် ရှာဖွေပါ...',
                      hintStyle:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchGroupCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () =>
                                  setState(() => _searchGroupCtrl.clear()),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textMuted),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'စုစုပေါင်း အုပ်စု: ${filteredGroups.length} ခု',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Groups Grid View
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(authProvider.notifier).loadRemoteUsers(),
                ref.read(permissionGroupProvider.notifier).loadGroups(),
              ]);
            },
            child: ref.watch(permissionGroupLoadingProvider) && filteredGroups.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'လုပ်ပိုင်ခွင့် အုပ်စုများ ရယူနေပါသည်...',
                      subMessage: 'Loading permission groups...',
                      icon: Icons.shield_rounded,
                    ),
                  )
                : filteredGroups.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('ရှာဖွေမှုနှင့် ကိုက်ညီသော Permission Group မရှိပါ',
                              style:
                                  TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                    final grp = filteredGroups[index];
                    final assignedUsersCount = authState.users
                        .where((u) => u.permissionGroupId == grp.id)
                        .length;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Text(grp.icon,
                                    style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          grp.name,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${grp.burmeseName})',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (grp.isBuiltIn)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            child: Text(
                                              'SYSTEM BUILT-IN',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'CUSTOM GROUP',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      grp.description,
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_outline_rounded,
                                        size: 15, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$assignedUsersCount Staff',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSuperAdmin) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined,
                                      size: 17, color: AppColors.textSecondary),
                                  tooltip: 'လုပ်ပိုင်ခွင့်များ ပြင်ဆင်မည်',
                                  onPressed: () =>
                                      _showAddEditGroupDialog(group: grp),
                                ),
                                if (!grp.isBuiltIn)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        size: 17, color: AppColors.error),
                                    tooltip: 'အုပ်စု ဖျက်မည်',
                                    onPressed: () => _confirmDeleteGroup(grp),
                                  ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Left Menu Permissions Checklist Display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'ဘယ်ဘက် Navigation Menu သုံးစွဲခွင့် အခြေအနေ (Permissions):',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${grp.permissions.length} / ${AppMenuPermission.values.length} Menus Allowed',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: AppMenuPermission.values.map((perm) {
                                    final isGranted =
                                        grp.permissions.contains(perm);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isGranted
                                            ? AppColors.primary
                                                .withValues(alpha: 0.18)
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isGranted
                                              ? AppColors.primary
                                              : AppColors.border
                                                  .withValues(alpha: 0.5),
                                          width: isGranted ? 1.2 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isGranted
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_outlined,
                                            size: 13,
                                            color: isGranted
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(perm.emoji,
                                              style:
                                                  const TextStyle(fontSize: 11)),
                                          const SizedBox(width: 4),
                                          Text(
                                            perm.burmeseLabel,
                                            style: TextStyle(
                                              color: isGranted
                                                  ? AppColors.textPrimary
                                                  : AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: isGranted
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              decoration: isGranted
                                                  ? null
                                                  : TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
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

  Widget _buildMetricCard({
    required String icon,
    required String title,
    required String burmese,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(burmese,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 9.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Add / Edit User Dialog (with Permission Group & Menu Toggles)
// ============================================================

class _AddEditUserDialog extends ConsumerStatefulWidget {
  const _AddEditUserDialog({this.userToEdit});
  final AppUser? userToEdit;

  @override
  ConsumerState<_AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends ConsumerState<_AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _phoneCtrl;

  late UserRole _role;
  late String _permissionGroupId;
  late List<AppMenuPermission> _selectedPermissions;
  String? _branchId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController(
      text: u != null ? u.password : 'pass123',
    );
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _role = u?.role ?? UserRole.cashier;
    _permissionGroupId = u?.permissionGroupId ??
        (u?.role == UserRole.owner
            ? 'pg_owner'
            : u?.role == UserRole.manager
                ? 'pg_manager'
                : 'pg_cashier');
    _branchId = u?.branchId ?? 'branch_a';
    _isActive = u?.isActive ?? true;

    // Load initial permissions
    final groups = ref.read(permissionGroupProvider);
    _selectedPermissions = List<AppMenuPermission>.from(
      u != null
          ? u.getAllowedMenus(groups)
          : (groups.where((g) => g.id == _permissionGroupId).firstOrNull?.permissions ??
              AppMenuPermission.values),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onPermissionGroupChanged(String newGroupId, List<PermissionGroup> groups) {
    setState(() {
      _permissionGroupId = newGroupId;
      final grp = groups.where((g) => g.id == newGroupId).firstOrNull;
      if (grp != null) {
        _selectedPermissions = List<AppMenuPermission>.from(grp.permissions);
      }
    });
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.userToEdit != null;
    bool ok;

    if (isEdit) {
      final updated = widget.userToEdit!.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        phone:
            _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        role: _role,
        permissionGroupId: _permissionGroupId,
        customPermissions: _selectedPermissions,
        branchId: _branchId,
        clearBranch: _branchId == null,
        isActive: _isActive,
      );
      ok = await ref.read(authProvider.notifier).updateUser(updated);
    } else {
      final newUser = AppUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        phone:
            _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        role: _role,
        permissionGroupId: _permissionGroupId,
        customPermissions: _selectedPermissions,
        branchId: _branchId,
        isActive: _isActive,
        createdAt: DateTime.now(),
      );
      ok = await ref.read(authProvider.notifier).addUser(newUser);
    }

    if (!ok || !mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit
            ? 'Successfully updated "${_nameCtrl.text}"'
            : 'Created new user account "${_nameCtrl.text}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userToEdit != null;
    final groups = ref.watch(permissionGroupProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 660,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Staff Account' : 'Add New Staff User',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'အသုံးပြုသူ အချက်အလက်နှင့် ဘယ်ဘက် Menu သုံးစွဲခွင့် ပြင်ဆင်ခြင်း'
                            : 'အသုံးပြုသူအသစ်နှင့် Permission Group သတ်မှတ်ခြင်း',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name & Phone
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Full Name (အမည်) *',
                                hintText: 'e.g. Ko Aung Myint',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Phone (ဖုန်းနံပါတ်)',
                                hintText: 'e.g. 09-791234567',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Email / Username & Password
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Email / Username (အကောင့်အမည်) *',
                                hintText: 'e.g. aung.pos@sitepyoe.com',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Email is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: isEdit
                                    ? 'New Password (စကားဝှက်အသစ် - မပြောင်းလိုပါက ချန်ထားပါ)'
                                    : 'Password (စကားဝှက်) *',
                                hintText: isEdit
                                    ? 'Leave blank to keep current password'
                                    : 'Minimum 4 characters',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (!isEdit && (v == null || v.trim().length < 4)) {
                                  return 'Min 4 characters required';
                                }
                                if (isEdit &&
                                    v != null &&
                                    v.trim().isNotEmpty &&
                                    v.trim().length < 4) {
                                  return 'Min 4 characters required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Role Dropdown & Branch Assignment
                      Row(
                        children: [
                          // Role
                          Expanded(
                            child: DropdownButtonFormField<UserRole>(
                              initialValue: _role,
                              dropdownColor: AppColors.surfaceVariant,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Role (ရာထူးတာဝန်)',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              items: UserRole.values.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                      '${r.icon}  ${r.label} (${r.burmeseLabel})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _role = val;
                                    // Auto suggest matching permission group
                                    if (val == UserRole.owner) {
                                      _permissionGroupId = 'pg_owner';
                                    } else if (val == UserRole.manager) {
                                      _permissionGroupId = 'pg_manager';
                                    } else if (val == UserRole.stockClerk) {
                                      _permissionGroupId = 'pg_stock';
                                    } else {
                                      _permissionGroupId = 'pg_cashier';
                                    }
                                    _onPermissionGroupChanged(
                                        _permissionGroupId, groups);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Branch
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _branchId,
                              dropdownColor: AppColors.surfaceVariant,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Assigned Branch (တာဝန်ကျဆိုင်ခွဲ)',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('🌐 All Branches (ဆိုင်ခွဲအားလုံး)'),
                                ),
                                ...kBranches.entries.map((e) {
                                  return DropdownMenuItem<String?>(
                                    value: e.key,
                                    child: Text('🏪 ${e.value}'),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _branchId = val);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── PERMISSION GROUP ASSIGNMENT ─────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Permission Group (လုပ်ပိုင်ခွင့်အုပ်စု သတ်မှတ်ခြင်း) *',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selectedPermissions.length} Menus Granted',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            DropdownButtonFormField<String>(
                              initialValue: groups.any((g) => g.id == _permissionGroupId)
                                  ? _permissionGroupId
                                  : (groups.isNotEmpty ? groups.first.id : null),
                              dropdownColor: AppColors.surface,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Select Permission Group (အုပ်စုရွေးချယ်ပါ)',
                                filled: true,
                                fillColor: AppColors.surface,
                                border: const OutlineInputBorder(),
                              ),
                              items: groups.map((g) {
                                return DropdownMenuItem(
                                  value: g.id,
                                  child: Text(
                                      '${g.icon}  ${g.name} (${g.burmeseName}) — ${g.permissions.length} Menus'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _onPermissionGroupChanged(val, groups);
                                }
                              },
                            ),

                            const SizedBox(height: 14),

                            Text(
                              'ဘယ်ဘက် Navigation Menu သုံးစွဲခွင့်များ စိတ်ကြိုက်ပြင်ဆင်ရန် (Menu Permissions):',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            // 7 Left Menu Checkboxes
                            ...AppMenuPermission.values.map((perm) {
                              final isChecked =
                                  _selectedPermissions.contains(perm);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                                value: isChecked,
                                title: Row(
                                  children: [
                                    Text(perm.emoji,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(
                                      perm.burmeseLabel,
                                      style: TextStyle(
                                        color: isChecked
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: isChecked
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${perm.label})',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  perm.description,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      if (!_selectedPermissions.contains(perm)) {
                                        _selectedPermissions.add(perm);
                                      }
                                    } else {
                                      _selectedPermissions.remove(perm);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Active switch checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isActive,
                            activeColor: AppColors.primary,
                            onChanged: (v) =>
                                setState(() => _isActive = v ?? true),
                          ),
                          Text(
                            'Active Account (အသုံးပြုခွင့်ပေးထားသည်)',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit & Cancel buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel (မလုပ်ပါ)',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveUser,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isEdit
                          ? 'Save Changes (သိမ်းမည်)'
                          : 'Create User (အကောင့်ဖွင့်မည်)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Add / Edit Permission Group Dialog
// ============================================================

class _AddEditPermissionGroupDialog extends ConsumerStatefulWidget {
  const _AddEditPermissionGroupDialog({this.groupToEdit});
  final PermissionGroup? groupToEdit;

  @override
  ConsumerState<_AddEditPermissionGroupDialog> createState() =>
      _AddEditPermissionGroupDialogState();
}

class _AddEditPermissionGroupDialogState
    extends ConsumerState<_AddEditPermissionGroupDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _burmeseNameCtrl;
  late TextEditingController _descCtrl;
  late String _selectedIcon;
  late List<AppMenuPermission> _selectedPermissions;

  static const _iconPresets = [
    '👑', '🏢', '💵', '📦', '🛡️', '💼', '🧑‍🌾', '🏷️', '🪴', '📊'
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.groupToEdit;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _burmeseNameCtrl = TextEditingController(text: g?.burmeseName ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _selectedIcon = g?.icon ?? '🛡️';
    _selectedPermissions = List<AppMenuPermission>.from(
        g?.permissions ?? [AppMenuPermission.pos, AppMenuPermission.orders]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _burmeseNameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အနည်းဆုံး Left Menu တစ်ခုအား ခွင့်ပြုချက် ပေးရပါမည်'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final isEdit = widget.groupToEdit != null;
    final notifier = ref.read(permissionGroupProvider.notifier);

    bool ok;
    if (isEdit) {
      ok = await notifier.updateGroup(
        id: widget.groupToEdit!.id,
        name: _nameCtrl.text.trim(),
        burmeseName: _burmeseNameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        icon: _selectedIcon,
        permissions: _selectedPermissions,
      );
    } else {
      ok = await notifier.addGroup(
        name: _nameCtrl.text.trim(),
        burmeseName: _burmeseNameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        icon: _selectedIcon,
        permissions: _selectedPermissions,
      );
    }

    if (!ok || !mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit
            ? 'Updated permission group "${_nameCtrl.text}"'
            : 'Created new permission group "${_nameCtrl.text}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.groupToEdit != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 740),
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_selectedIcon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'Edit Permission Group'
                            : 'Add New Permission Group',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'ဘယ်ဘက် Menu သုံးစွဲခွင့်များနှင့် အုပ်စုအမည် ပြင်ဆင်ခြင်း'
                            : 'ဘယ်ဘက် Menu သုံးစွဲခွင့် အုပ်စုအသစ် သတ်မှတ်ခြင်း',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon presets
                      Text('အိုင်ကွန် / အီမိုဂျီ ရွေးချယ်ပါ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _iconPresets.map((e) {
                          final isSel = _selectedIcon == e;
                          return InkWell(
                            onTap: () => setState(() => _selectedIcon = e),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isSel
                                        ? AppColors.primary
                                        : AppColors.border),
                              ),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Group Name (English & Burmese)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Group Name (English) *',
                                hintText: 'e.g. Cashier / Floor Staff',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Group name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _burmeseNameCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'အုပ်စုအမည် (မြန်မာ) *',
                                hintText: 'ဥပမာ - ငွေကိုင် / အရောင်းဝန်ထမ်း',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'မြန်မာအမည် ထည့်သွင်းပေးပါ'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Description (လုပ်ပိုင်ခွင့် ရှင်းလင်းချက်)',
                          hintText:
                              'ဥပမာ - နေ့စဉ်အရောင်း (POS) နှင့် ဘောက်ချာများသာ သုံးစွဲခွင့်ရှိသည်',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Left Menu Checkboxes
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ဘယ်ဘက် Navigation Menu သုံးစွဲခွင့်များ သတ်မှတ်ပါ (Permissions):',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selectedPermissions.length} / 7 Allowed',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ...AppMenuPermission.values.map((perm) {
                              final isChecked =
                                  _selectedPermissions.contains(perm);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                                value: isChecked,
                                title: Row(
                                  children: [
                                    Text(perm.emoji,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(
                                      perm.burmeseLabel,
                                      style: TextStyle(
                                        color: isChecked
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: isChecked
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${perm.label})',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10.5),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  perm.description,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      if (!_selectedPermissions.contains(perm)) {
                                        _selectedPermissions.add(perm);
                                      }
                                    } else {
                                      _selectedPermissions.remove(perm);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('မလုပ်တော့ပါ (Cancel)',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(isEdit
                        ? 'Save Changes (သိမ်းမည်)'
                        : 'Create Group (အုပ်စုဖွင့်မည်)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
