import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../../settings/view_models/permission_group_notifier.dart';
import '../view_models/inventory_notifier.dart';
import 'add_product_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, this.onNavigateToWastage, this.onNavigateToTransfer});

  final VoidCallback? onNavigateToWastage;
  final VoidCallback? onNavigateToTransfer;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _selectedBranch = 'branch_a';
  String _selectedCategoryId = 'all';
  bool _onlyLowStock = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showEditProductDialog(ProductWithStock item) {
    final inv = ref.read(inventoryProvider);
    final stockA = inv.getStock('branch_a', item.product.id);
    final stockB = inv.getStock('branch_b', item.product.id);
    AddProductDialog.show(
      context,
      productToEdit: item.product,
      initialBranchStockA: stockA,
      initialBranchStockB: stockB,
    );
  }

  void _confirmDeleteProduct(MockProduct product) {
    final authState = ref.read(authProvider);
    final permissionGroups = ref.read(permissionGroupProvider);
    if (!(authState.currentUser?.canDeleteData(permissionGroups) ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'ဒေတာနှင့် မှတ်တမ်းများ ပယ်ဖျက်ခွင့် (Delete Permission) မရှိပါ။ Super Admin ထံ ခွင့်ပြုချက်တောင်းခံပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'ပစ္စည်းဖျက်ရန် အတည်ပြုပါ',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '${product.imageEmoji} "${product.name}" (${product.sku}) ကို ကုန်ပစ္စည်းစာရင်းမှ ဖျက်ပစ်ရန် သေချာပါသလား?\nဤလုပ်ဆောင်ချက်ကို ပြန်လည်ပြင်ဆင်၍ မရနိုင်ပါ။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('မလုပ်တော့ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(catalogProvider.notifier).deleteProduct(product.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${product.name}" ကို ကုန်ပစ္စည်းစာရင်းမှ ပယ်ဖျက်ပြီးပါပြီ။'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('ဖျက်မည် (Delete)'),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(ProductWithStock item) {
    final qtyCtrl = TextEditingController(text: '${item.stock}');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'လက်ကျန်စစ်ဆေးပြင်ဆင်ခြင်း: ${item.product.name}',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ဆိုင်ခွဲ: ${kBranches[_selectedBranch] ?? _selectedBranch}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'လက်ရှိ ရေတွက်ရရှိသော အရေအတွက် (Physical count):',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('မလုပ်တော့ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text.trim());
                if (qty != null && qty >= 0) {
                  final ok = await ref.read(inventoryProvider.notifier).setStock(
                        _selectedBranch,
                        item.product.id,
                        qty,
                      );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.product.name} လက်ကျန်အရေအတွက်ကို $qty ခုအဖြစ် သိမ်းဆည်းပြီးပါပြီ။'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('သိမ်းဆည်းမည် (Save Count)'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(branchesProvider);
    final activeCategories = ref.watch(categoryNotifierProvider);
    final authState = ref.watch(authProvider);
    final permissionGroups = ref.watch(permissionGroupProvider);
    final canDelete = authState.currentUser?.canDeleteData(permissionGroups) ?? false;
    final isCatalogLoading = ref.watch(catalogLoadingProvider);
    final currencyFmt = NumberFormat('#,###');
    final allProducts = ref.watch(branchInventoryProvider(_selectedBranch));

    final selectedCatItem = _selectedCategoryId == 'all'
        ? null
        : activeCategories
            .where((c) => c.id == _selectedCategoryId)
            .firstOrNull;

    // Filter products
    final filtered = allProducts.where((item) {
      if (_onlyLowStock && !item.isLowStock) {
        return false;
      }
      if (_selectedCategoryId != 'all') {
        final matched = item.product.matchesCategory(
          selectedCategoryId: _selectedCategoryId,
          standardCategory: selectedCatItem?.standardCategory,
          catName: selectedCatItem?.name,
          catEnglishName: selectedCatItem?.englishName,
        );
        if (!matched) return false;
      }
      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        final match = item.product.name.toLowerCase().contains(q) ||
            item.product.sku.toLowerCase().contains(q) ||
            (item.product.barcode != null && item.product.barcode!.contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();

    // Summary metrics
    final totalSkus = filtered.length;
    final totalUnits = filtered.fold(0, (sum, i) => sum + i.stock);
    final totalValuation = filtered.fold(0.0, (sum, i) => sum + (i.stock * i.product.costPrice));
    final lowStockCount = filtered.where((i) => i.isLowStock).length;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ── Top Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Branch Inventory Management',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ဆိုင်ခွဲအလိုက် ပစ္စည်းလက်ကျန်စာရင်းနှင့် စစ်ဆေးမှု',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Branch Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: kBranches.containsKey(_selectedBranch)
                          ? _selectedBranch
                          : (kBranches.keys.firstOrNull ?? _selectedBranch),
                      dropdownColor: AppColors.surfaceVariant,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                      items: kBranches.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranch = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // + Add New Product button
                ElevatedButton.icon(
                  onPressed: () => AddProductDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    '+ ပစ္စည်းသစ်ထည့်မည်',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // ── Filter & Search Toolbar ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ပစ္စည်းအမည်၊ SKU သို့မဟုတ် ဘားကုဒ် ရှာဖွေပါ...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category Tabs
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              'အားလုံး',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _selectedCategoryId == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedCategoryId == 'all'
                                    ? AppColors.textOnPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: _selectedCategoryId == 'all',
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = 'all'),
                          ),
                        ),
                        ...activeCategories.map((c) {
                          final selected = _selectedCategoryId == c.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                '${c.emoji} ${c.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? AppColors.textOnPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              onSelected: (_) =>
                                  setState(() => _selectedCategoryId = c.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Low Stock Toggle
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: _onlyLowStock ? AppColors.warning : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'လက်ကျန်နည်း ($lowStockCount)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _onlyLowStock ? FontWeight.bold : FontWeight.normal,
                          color: _onlyLowStock ? AppColors.warning : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  selected: _onlyLowStock,
                  selectedColor: AppColors.warning.withValues(alpha: 0.2),
                  backgroundColor: AppColors.surface,
                  onSelected: (v) => setState(() => _onlyLowStock = v),
                ),
              ],
            ),
          ),

          // ── Stat Summary Strip ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'အမျိုးအမည်: $totalSkus မျိုး  •  စုစုပေါင်း: $totalUnits ခု  •  တန်ဖိုး: ${currencyFmt.format(totalValuation)} ကျပ်',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => AddProductDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'ပစ္စည်းထည့်မည်',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 6),
                if (widget.onNavigateToWastage != null)
                  TextButton.icon(
                    onPressed: widget.onNavigateToWastage,
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 14, color: AppColors.error),
                    label: const Text('ပျက်စီး/သေဆုံး မှတ်တမ်း', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                if (widget.onNavigateToTransfer != null)
                  TextButton.icon(
                    onPressed: widget.onNavigateToTransfer,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
                    label: const Text('ဆိုင်ခွဲသို့ လွှဲပြောင်း', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
              ],
            ),
          ),

          // ── Products Table / List ─────────────────────────────
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
              child: isCatalogLoading && filtered.isEmpty
                  ? const Center(
                      child: AppLoadingView(
                        message: 'ပစ္စည်းလက်ကျန် စာရင်းများ ရယူနေပါသည်...',
                        subMessage: 'Loading inventory stocks...',
                      ),
                    )
                  : filtered.isEmpty
                      ? CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  'ရှာဖွေမှုနှင့် ကိုက်ညီသော ကုန်ပစ္စည်း မရှိပါ',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ],
                        )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final p = item.product;
                      final isLow = item.isLowStock;
                      final isOut = item.isOutOfStock;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOut
                                ? AppColors.error.withValues(alpha: 0.5)
                                : isLow
                                    ? AppColors.warning.withValues(alpha: 0.4)
                                    : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            ProductAvatar(
                              imageEmoji: p.imageEmoji,
                              customImagePath: p.customImagePath,
                              size: 36,
                              fontSize: 26,
                            ),
                            const SizedBox(width: 14),
                            // Product details
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (p.originType != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.originType == OriginType.thaiImport
                                                ? 'ယိုးဒယား Import'
                                                : p.originType == OriginType.chinaImport
                                                    ? 'တရုတ် Import'
                                                    : 'ပြည်တွင်း',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: ${p.sku}  •  အမျိုးအစား: ${p.categoryName != null && p.categoryName!.isNotEmpty ? p.categoryName! : switch (p.category) {
                                      ProductCategory.all => 'အားလုံး',
                                      ProductCategory.plants => 'အပင်',
                                      ProductCategory.pots => 'ပန်းအိုး',
                                      ProductCategory.chemicals => 'မြေသြဇာ/ဆေး',
                                      ProductCategory.tools => 'ကိရိယာ',
                                      ProductCategory.others => 'အခြား',
                                    }}${p.subcategory.isNotEmpty ? ' (${p.subcategory})' : ''}',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Pricing
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ရောင်းဈေး: ${currencyFmt.format(p.salePrice)} ကျပ်',
                                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    'အရင်း: ${currencyFmt.format(p.costPrice)} ကျပ်',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Stock status
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isOut
                                          ? AppColors.error
                                          : isLow
                                              ? AppColors.warning.withValues(alpha: 0.15)
                                              : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isOut
                                            ? AppColors.error
                                            : isLow
                                                ? AppColors.warning
                                                : AppColors.primary,
                                      ),
                                    ),
                                    child: Text(
                                      isOut ? 'ပစ္စည်းပြတ် (OUT OF STOCK)' : 'လက်ကျန် ${item.stock} ခု',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isOut
                                            ? Colors.white
                                            : isLow
                                                ? AppColors.warning
                                                : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Full Product Edit (အမည်၊ ဈေးနှုန်း၊ အမျိုးအစား အပြည့်အစုံ ပြင်ဆင်ရန်)
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                  tooltip: 'ကုန်ပစ္စည်းအချက်အလက် ပြင်ဆင်မည် (Edit Product)',
                                  onPressed: () => _showEditProductDialog(item),
                                ),
                                // Adjust Stock Count (လက်ကျန်အရေအတွက် အမြန်စစ်ဆေးပြင်ဆင်ရန်)
                                IconButton(
                                  icon: const Icon(Icons.tune_rounded, color: AppColors.primaryLight, size: 20),
                                  tooltip: 'လက်ကျန်အရေအတွက် စစ်ဆေးပြင်ဆင်မည် (Adjust Stock Count)',
                                  onPressed: () => _showAdjustStockDialog(item),
                                ),
                                // Delete Product (ပယ်ဖျက်ရန် - requires delete_data permission)
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    tooltip: 'ပစ္စည်းဖျက်မည် (Delete Product)',
                                    onPressed: () => _confirmDeleteProduct(item.product),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
