import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../view_models/cart_notifier.dart';
import '../view_models/pos_filter_notifier.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/cart_panel.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/payment_dialog.dart';
import '../../branch_transfer/views/transfer_screen.dart';
import '../../inventory/views/inventory_screen.dart';
import '../../reports/views/reports_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../wastage/views/wastage_screen.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

import 'package:intl/intl.dart';
import '../../../../data/models/app_permission.dart';
import '../../orders/views/order_history_screen.dart';
import '../../settings/view_models/permission_group_notifier.dart';
import '../../purchases/views/purchase_screen.dart';
import '../../hr_payroll/views/hr_payroll_screen.dart';
import '../widgets/held_orders_dialog.dart';

// ── Global nav state ──────────────────────────────────────
final _navIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================
// POS Screen — root scaffold
// ============================================================

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIdx = ref.watch(_navIndexProvider);
    final authState = ref.watch(authProvider);
    final permissionGroups = ref.watch(permissionGroupProvider);

    // Retrieve dynamically allowed Left Side Menu items for current active user
    final allowedMenus = authState.currentUser?.getAllowedMenus(permissionGroups) ??
        AppMenuPermission.values;

    // Safety fallback: If current navIdx is not among user's allowed menus, auto-switch to first allowed menu
    final menuItems = allowedMenus.where((p) => p.isMenu).toList();
    final isAllowed = menuItems.any((p) => p.navIndex == navIdx);
    final effectiveNavIdx = isAllowed
        ? navIdx
        : (menuItems.isNotEmpty ? menuItems.first.navIndex : 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Navigation Rail (72 px fixed) ─────────────────
          _SideNavRail(
            selectedIndex: effectiveNavIdx,
            allowedMenus: allowedMenus,
            onSelect: (i) =>
                ref.read(_navIndexProvider.notifier).state = i,
          ),

          // ── Main body ─────────────────────────────────────
          Expanded(
            child: switch (effectiveNavIdx) {
              0 => const _PosBody(),
              1 => OrderHistoryScreen(
                  onNavigateToPos: () =>
                      ref.read(_navIndexProvider.notifier).state = 0,
                ),
              2 => InventoryScreen(
                  onNavigateToWastage: () =>
                      ref.read(_navIndexProvider.notifier).state = 4,
                  onNavigateToTransfer: () =>
                      ref.read(_navIndexProvider.notifier).state = 3,
                ),
              3 => const TransferScreen(),
              4 => const WastageScreen(),
              5 => const ReportsScreen(),
              6 => const SettingsScreen(),
              7 => const PurchaseScreen(),
              8 => const HrPayrollScreen(),
              _ => const _PosBody(),
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Side Navigation Rail
// ============================================================

class _SideNavRail extends ConsumerWidget {
  const _SideNavRail({
    required this.selectedIndex,
    required this.allowedMenus,
    required this.onSelect,
  });
  final int selectedIndex;
  final List<AppMenuPermission> allowedMenus;
  final ValueChanged<int> onSelect;

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).currentUser;

    final topMenus = allowedMenus.where((p) => p.isMenu && p != AppMenuPermission.settings).toList();
    final settingsPerm = allowedMenus.cast<AppMenuPermission?>().firstWhere(
      (p) => p == AppMenuPermission.settings,
      orElse: () => null,
    );

    Widget buildNavItem(AppMenuPermission perm) {
      final idx = perm.navIndex;
      final selected = selectedIndex == idx;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Tooltip(
          message: '${perm.burmeseLabel} (${perm.label})',
          child: GestureDetector(
            onTap: () => onSelect(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? perm.icon : perm.outlineIcon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    perm.burmeseLabel.replaceAll(' / ', '\n'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 8,
                      height: 1.15,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 72,
      color: AppColors.navRailBg,
      child: Column(
        children: [
          // App logo / brand mark
          Container(
            height: 62,
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 6),

          // Operational Nav items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: topMenus.map(buildNavItem).toList(),
              ),
            ),
          ),

          // Active User Avatar & Role (Tap to view profile / sign out)
          if (currentUser != null) ...[
            Tooltip(
              message: '${currentUser.name}\n${currentUser.role.label}\n${currentUser.email}\n(နှိပ်၍ အကောင့်ထွက်နိုင်ပါသည်)',
              child: GestureDetector(
                onTap: () => _confirmLogout(context, ref),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentUser.role.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentUser.name.split(' ').first,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Setting Menu (Under login profile icon)
          if (settingsPerm != null) ...[
            buildNavItem(settingsPerm),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// POS Body — dual-pane layout
// ============================================================

class _PosBody extends ConsumerStatefulWidget {
  const _PosBody();

  @override
  ConsumerState<_PosBody> createState() => _PosBodyState();
}

class _PosBodyState extends ConsumerState<_PosBody> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() =>
      ref.read(posFilterProvider.notifier).updateSearch(_searchCtrl.text);

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onHold() {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final customerCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

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
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pause_circle_filled_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'အော်ဒါ #${cart.ticketNumber} ဆိုင်းငံ့မည်လား?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ခြင်းတောင်းထဲတွင် ပစ္စည်း ${cart.itemCount} ခု (${NumberFormat('#,###').format(cart.totalAmount)} ကျပ်) ပါဝင်ပါသည်။ ဝယ်သူအမည် သို့မဟုတ် မှတ်ချက် ထည့်သွင်းဆိုင်းငံ့နိုင်ပါသည်။',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: customerCtrl,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'ဝယ်သူအမည် / စားပွဲအမှတ် (Customer Name - စိတ်ကြိုက်)',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'မှတ်ချက် (Note - ဥပမာ - ATM ငွေထုတ်စောင့်)',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final custName = customerCtrl.text.trim();
              final note = noteCtrl.text.trim();
              Navigator.of(ctx).pop();
              final held = ref.read(cartProvider.notifier).holdCurrentCart(
                    customerName: custName.isNotEmpty ? custName : null,
                    note: note.isNotEmpty ? note : null,
                  );
              if (held != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Row(
                      children: [
                        const Icon(Icons.pause_circle_filled_rounded,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'အော်ဒါ #${held.ticketNumber} ကို ဆိုင်းငံ့ထားပါပြီ',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    action: SnackBarAction(
                      label: 'ဆိုင်းငံ့စာရင်းကြည့်',
                      textColor: AppColors.warning,
                      onPressed: () => HeldOrdersDialog.show(context),
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ဆိုင်းငံ့မည် (Hold Order)',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(branchesProvider);
    final products = ref.watch(filteredProductsProvider);
    final isCatalogLoading = ref.watch(catalogLoadingProvider);
    final filter = ref.watch(posFilterProvider);
    final filterNotify = ref.read(posFilterProvider.notifier);

    return Row(
      children: [
        // ── Left Pane 65% ─────────────────────────────────
        Expanded(
          flex: 65,
          child: Column(
            children: [
              // Top search bar + branch selector
              _TopBar(
                searchCtrl:       _searchCtrl,
                selectedBranchId: filter.selectedBranchId,
                onBranchChange:   filterNotify.selectBranch,
              ),

              // Category tabs + sub-filter chips
              const CategoryFilterBar(),

              // Product count indicator
              _ProductCountBar(count: products.length),

              // Product grid with Pull-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(branchesProvider.notifier).loadBranches(),
                      ref.read(catalogProvider.notifier).loadProducts(),
                      ref.read(categoryNotifierProvider.notifier).loadCategories(),
                    ]);
                  },
                  child: isCatalogLoading && products.isEmpty
                      ? const Center(
                          child: AppLoadingView(
                            message: 'အရောင်းကောင်တာ ကုန်ပစ္စည်းများ ရယူနေပါသည်...',
                            subMessage: 'Loading products from database...',
                          ),
                        )
                      : products.isEmpty
                          ? const CustomScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _EmptyProducts(),
                                ),
                              ],
                            )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 175,
                            mainAxisExtent: 165,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, i) =>
                              ProductGridItem(product: products[i]),
                        ),
                ),
              ),
            ],
          ),
        ),

        // ── Right Pane 35% ────────────────────────────────
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.328,
          child: CartPanel(
            onHold:     _onHold,
            onCheckout: () => _showCheckoutDialog(context),
          ),
        ),
      ],
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const PaymentDialog(),
    );
  }
}

// ── Top search bar ────────────────────────────────────────

class _TopBar extends ConsumerStatefulWidget {
  const _TopBar({
    required this.searchCtrl,
    required this.selectedBranchId,
    required this.onBranchChange,
  });
  final TextEditingController searchCtrl;
  final String selectedBranchId;
  final ValueChanged<String> onBranchChange;

  @override
  ConsumerState<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<_TopBar> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heldOrders = ref.watch(cartProvider).heldOrders;
    final pendingSyncCount = ref.watch(syncPendingCountProvider);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navRailBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search input
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: widget.searchCtrl,
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  hintText: 'ပစ္စည်းအမည်၊ အမျိုးအစား၊ ကုန်သည်၊ မူရင်းဒေသ၊ SKU ဖြင့် ရှာဖွေပါ...',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  suffixIcon: widget.searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: widget.searchCtrl.clear,
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted),
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Barcode / camera scan button
          Tooltip(
            message: 'ဘားကုဒ် စကင်ဖတ်ရန် (Scan barcode)',
            child: GestureDetector(
              onTap: () {
                // TODO: launch mobile_scanner
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ဘားကုဒ် စကင်ဖတ်စနစ် — မကြာမီ ရရှိပါမည်'),
                      duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Branch selector
          _BranchBadge(
            selectedBranchId: widget.selectedBranchId,
            onChanged: widget.onBranchChange,
          ),

          const SizedBox(width: 8),

          // Cloud Sync & Connection indicator
          Tooltip(
            message: pendingSyncCount > 0
                ? 'အင်တာနက်ပြတ်တောက်စဉ် ရောင်းချထားသော စာရင်း $pendingSyncCount ခုရှိပါသည် (နှိပ်၍ Cloud ပေါ်သို့ တင်ပါ)'
                : 'Cloud Server နှင့် ချိတ်ဆက်မှု အဆင်ပြေပါသည် (စနစ်အားလုံး Update ဖြစ်နေပါသည်)',
            child: InkWell(
              onTap: () async {
                final count = await ref.read(syncServiceProvider).updatePendingCount();
                if (count > 0) {
                  AppToast.showInfo('Cloud Server သို့ စာရင်းများ ပေးပို့နေပါသည်...');
                  await ref.read(syncServiceProvider).syncPendingQueue();
                } else {
                  AppToast.showSuccess('အချက်အလက်အားလုံး Cloud ပေါ်တွင် မွမ်းမံပြီးပါပြီ');
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: pendingSyncCount > 0
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: pendingSyncCount > 0
                        ? AppColors.warning.withValues(alpha: 0.4)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pendingSyncCount > 0
                          ? Icons.cloud_upload_outlined
                          : Icons.cloud_done_rounded,
                      size: 16,
                      color: pendingSyncCount > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pendingSyncCount > 0
                          ? 'Sync ($pendingSyncCount)'
                          : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pendingSyncCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Held Orders button if any
          if (heldOrders.isNotEmpty) ...[
            Tooltip(
              message: 'ဆိုင်းငံ့ထားသော အော်ဒါများ (${heldOrders.length})',
              child: ElevatedButton.icon(
                onPressed: () => HeldOrdersDialog.show(context),
                icon: const Icon(Icons.pause_circle_filled_rounded, size: 16),
                label: Text(
                  'ဆိုင်းငံ့ (${heldOrders.length})',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Orders / History quick button
          Tooltip(
            message: 'အရောင်းဘောက်ချာ မှတ်တမ်း (Orders)',
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(_navIndexProvider.notifier).state = 1,
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text(
                'ဘောက်ချာများ',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branch badge + dropdown ───────────────────────────────

class _BranchBadge extends StatelessWidget {
  const _BranchBadge({
    required this.selectedBranchId,
    required this.onChanged,
  });
  final String selectedBranchId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedBranchId,
      onSelected: onChanged,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                kBranches[selectedBranchId] ?? 'Branch A',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
      itemBuilder: (_) => kBranches.entries
          .map((e) => PopupMenuItem<String>(
                value: e.key,
                child: Text(e.value,
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 12)),
              ))
          .toList(),
    );
  }
}

// ── Product count bar ─────────────────────────────────────

class _ProductCountBar extends StatelessWidget {
  const _ProductCountBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            'ရရှိနိုင်သော ကုန်ပစ္စည်း: $count မျိုး',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('ရှာဖွေမှုနှင့် ကိုက်ညီသော ကုန်ပစ္စည်း မရှိပါ',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('အခြား အမည် သို့မဟုတ် အမျိုးအစား ရွေးချယ်ရှာဖွေပါ',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}


