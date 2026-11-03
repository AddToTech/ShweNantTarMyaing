// ============================================================
// PurchaseScreen  — အဝယ်စာရင်း (Stock-In / Purchase Invoice)
// Two-tab layout:
//   Tab 0 — New Purchase   (line-item builder + payment panel)
//   Tab 1 — Purchase History (searchable, filterable list)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/mock/mock_purchases.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../inventory/views/add_product_dialog.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../view_models/vendor_notifier.dart';
import '../view_models/purchase_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

// ── Number formatters ─────────────────────────────────────────
final _mmk = NumberFormat('#,##0', 'en_US');
final _qty = NumberFormat('#,##0.##', 'en_US');
final _dateFmt = DateFormat('dd MMM yyyy');

// ── PurchaseScreen ────────────────────────────────────────────
class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ───────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'အဝယ်စာရင်း — Purchases / Stock-In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'ကုန်သည်ထံမှ ပစ္စည်းဝယ်ယူ — ပိုင်ဆိုင်မှုလက်ကျန် ချက်ချင်း တိုးခြင်း',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.add_shopping_cart_rounded), text: 'ဝယ်ယူမှု သစ်'),
                  Tab(icon: Icon(Icons.receipt_long_rounded), text: 'မှတ်တမ်း'),
                ],
              ),
            ],
          ),
        ),

        // ── Body ─────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _NewPurchaseTab(onPurchaseSubmitted: () => _tab.animateTo(1)),
              const _PurchaseHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 0 — New Purchase
// ══════════════════════════════════════════════════════════════

class _NewPurchaseTab extends ConsumerStatefulWidget {
  const _NewPurchaseTab({required this.onPurchaseSubmitted});
  final VoidCallback onPurchaseSubmitted;

  @override
  ConsumerState<_NewPurchaseTab> createState() => _NewPurchaseTabState();
}

class _NewPurchaseTabState extends ConsumerState<_NewPurchaseTab> {
  // Header state
  String _branchId = 'branch_a';
  Vendor? _selectedVendor;
  DateTime _purchaseDate = DateTime.now();
  final _notesCtrl = TextEditingController();

  // Line items
  final List<_DraftItem> _draftItems = [];

  // Payment state
  PurchasePaymentStatus _paymentStatus = PurchasePaymentStatus.unpaid;
  final _paidCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');

  // Product search
  String _searchQuery = '';
  String _filterCategoryId = 'all';

  @override
  void dispose() {
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _draftItems.fold(0, (s, i) => s + i.totalCost);
  double get _discount  => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total     => (_subtotal - _discount).clamp(0, double.infinity);
  double get _paid      => double.tryParse(_paidCtrl.text) ?? 0;
  double get _balance   => (_total - _paid).clamp(0, double.infinity);

  void _addOrIncrement(MockProduct product) {
    final idx = _draftItems.indexWhere((i) => i.productId == product.id);
    setState(() {
      if (idx >= 0) {
        _draftItems[idx] = _draftItems[idx].copyWith(
          quantity: _draftItems[idx].quantity + 1,
        );
      } else {
        _draftItems.add(_DraftItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitCost: product.costPrice,
        ));
      }
    });
  }

  void _removeItem(int idx) => setState(() => _draftItems.removeAt(idx));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _showQuickAddVendorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('ကုန်သည်သစ် အမြန်ထည့်မည်',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ကုန်သည် အမည် *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'ဖုန်းနံပါတ်'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('မလုပ်တော့ပါ'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newlyAdded = await ref.read(vendorProvider.notifier).addVendor(
                name: name,
                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
              );
              if (newlyAdded != null && ctx.mounted) {
                setState(() => _selectedVendor = newlyAdded);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('သိမ်းမည်'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_draftItems.isEmpty) {
      _snack('ပစ္စည်း အနည်းဆုံး (၁) မျိုး ထည့်သွင်းပါ။');
      return;
    }

    final authState = ref.read(authProvider);

    final ok = await ref.read(purchaseProvider.notifier).submitPurchase(
      branchId: _branchId,
      vendorId: _selectedVendor?.id,
      vendorName: _selectedVendor?.name,
      purchaseDate: _purchaseDate,
      items: _draftItems
          .map((d) => PurchaseItem(
                productId: d.productId,
                productName: d.productName,
                quantity: d.quantity,
                unitCost: d.unitCost,
              ))
          .toList(),
      discount: _discount,
      paidAmount: _paid,
      paymentStatus: _paymentStatus,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdBy: authState.currentUser?.name,
    );

    if (!ok || !mounted) return;

    _snack(
      '✅ ဝယ်ယူမှု မှတ်တမ်းတင်ပြီး — ပစ္စည်းလက်ကျန် ချက်ချင်း တိုးသွားပါပြီ',
      isSuccess: true,
    );

    setState(() {
      _draftItems.clear();
      _selectedVendor = null;
      _purchaseDate = DateTime.now();
      _notesCtrl.clear();
      _paidCtrl.text = '0';
      _discountCtrl.text = '0';
      _paymentStatus = PurchasePaymentStatus.unpaid;
    });

    widget.onPurchaseSubmitted();
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    await AddProductDialog.show(context);
    if (mounted) {
      await ref.read(catalogProvider.notifier).loadProducts();
    }
  }

  void _snack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(catalogProvider);
    final isCatalogLoading = ref.watch(catalogLoadingProvider);
    final activeCategories = ref.watch(categoryNotifierProvider);
    final selectedCatItem = _filterCategoryId == 'all'
        ? null
        : activeCategories.where((c) => c.id == _filterCategoryId).firstOrNull;

    final filteredProducts = allProducts.where((p) {
      if (_filterCategoryId != 'all') {
        final matched = p.matchesCategory(
          selectedCategoryId: _filterCategoryId,
          standardCategory: selectedCatItem?.standardCategory,
          catName: selectedCatItem?.name,
          catEnglishName: selectedCatItem?.englishName,
        );
        if (!matched) return false;
      }
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Row(
      children: [
        // ── LEFT: Product picker ─────────────────────────────
        SizedBox(
          width: 420,
          child: Column(
            children: [
              // Branch + vendor selector
              _buildInvoiceHeader(),
              const Divider(height: 1),
              // Search & category filter
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'ကုန်ပစ္စည်း ရှာဖွေ...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'ပစ္စည်းအသစ် ထည့်သွင်းမည် (Add New Product)',
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddProductDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              '+ ပစ္စည်းသစ်',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CategoryFilterChips(
                      categories: activeCategories,
                      selectedCategoryId: _filterCategoryId,
                      onSelect: (id) => setState(() => _filterCategoryId = id),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Product list
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(branchesProvider.notifier).loadBranches(),
                      ref.read(catalogProvider.notifier).loadProducts(),
                      ref.read(categoryNotifierProvider.notifier).loadCategories(),
                      ref.read(vendorProvider.notifier).loadVendors(),
                      ref.read(purchaseProvider.notifier).loadPurchases(),
                    ]);
                  },
                  child: isCatalogLoading && filteredProducts.isEmpty
                      ? const Center(
                          child: AppLoadingView(
                            message: 'ကုန်ပစ္စည်းစာရင်းများ ရယူနေပါသည်...',
                            subMessage: 'Loading products for purchase...',
                            icon: Icons.inventory_2_rounded,
                          ),
                        )
                      : filteredProducts.isEmpty
                          ? CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 44,
                                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                      const SizedBox(height: 10),
                                      Text(
                                        'ကုန်ပစ္စည်း မတွေ့ပါ',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ဝယ်ယူမည့်ပစ္စည်း စာရင်းထဲတွင် မရှိသေးပါက အောက်ပါခလုတ်ကိုနှိပ်၍ ထည့်သွင်းပါ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAddProductDialog(context),
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text(
                                          '+ ပစ္စည်းအသစ် ထည့်သွင်းမည်',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textOnPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (ctx, i) =>
                              _ProductPickerTile(
                                product: filteredProducts[i],
                                branchId: _branchId,
                                onTap: () => _addOrIncrement(filteredProducts[i]),
                              ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // ── RIGHT: Draft items + payment ─────────────────────
        Expanded(
          child: Column(
            children: [
              // Items header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: AppColors.surfaceVariant,
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ဝယ်ယူမည့် ပစ္စည်းများ (${_draftItems.length} မျိုး)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_draftItems.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() => _draftItems.clear()),
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('ဖျက်မည်'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Line items
              Expanded(
                child: _draftItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'ဘယ်ဘက်မှ ပစ္စည်းရွေးချယ်ပါ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _draftItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) => _DraftItemRow(
                          item: _draftItems[i],
                          onQtyChanged: (qty) => setState(
                              () => _draftItems[i] = _draftItems[i].copyWith(quantity: qty)),
                          onCostChanged: (cost) => setState(
                              () => _draftItems[i] = _draftItems[i].copyWith(unitCost: cost)),
                          onRemove: () => _removeItem(i),
                        ),
                      ),
              ),

              const Divider(height: 1),
              // Payment panel
              _PaymentPanel(
                subtotal: _subtotal,
                discountCtrl: _discountCtrl,
                paidCtrl: _paidCtrl,
                paymentStatus: _paymentStatus,
                notesCtrl: _notesCtrl,
                onStatusChanged: (s) => setState(() {
                  _paymentStatus = s;
                  if (s == PurchasePaymentStatus.paid) {
                    _paidCtrl.text = _total.toStringAsFixed(0);
                  } else if (s == PurchasePaymentStatus.unpaid) {
                    _paidCtrl.text = '0';
                  }
                }),
                onChanged: () => setState(() {}),
                total: _total,
                balance: _balance,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHeader() {
    final vendors = ref.watch(vendorProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch selector (dropdown for multiple branches)
          Row(
            children: [
              const Icon(Icons.store_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('ဆိုင်ခွဲ:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: kBranches.containsKey(_branchId) ? _branchId : kBranches.keys.first,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  dropdownColor: AppColors.surfaceVariant,
                  hint: const Text(
                    'ဆိုင်ခွဲ ရွေးချယ်ပါ',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: kBranches.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _branchId = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _dateFmt.format(_purchaseDate),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Vendor selector
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('ကုန်သည်:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedVendor?.id,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  hint: const Text('ကုန်သည် (Vendor) ရွေးချယ်ပါ',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  items: vendors
                      .where((v) => v.isActive)
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() {
                    _selectedVendor =
                        id == null ? null : vendors.firstWhere((v) => v.id == id);
                  }),
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: () => _showQuickAddVendorDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ အသစ်', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Category Filter Chips
// ══════════════════════════════════════════════════════════════
class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });
  final List<CategoryItem> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('အားလုံး', style: TextStyle(fontSize: 11)),
              selected: selectedCategoryId == 'all',
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              onSelected: (_) => onSelect('all'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ),
          ...categories.map((cat) {
            final isSelected = cat.id == selectedCategoryId;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${cat.emoji} ${cat.name}',
                    style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                onSelected: (_) => onSelect(cat.id),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Product Picker Tile
// ══════════════════════════════════════════════════════════════
class _ProductPickerTile extends ConsumerWidget {
  const _ProductPickerTile({
    required this.product,
    required this.branchId,
    required this.onTap,
  });
  final MockProduct product;
  final String branchId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(inventoryProvider).getStock(branchId, product.id);

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ProductAvatar(
                imageEmoji: product.imageEmoji,
                customImagePath: product.customImagePath,
                size: 24,
                fontSize: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      'SKU: ${product.sku.isEmpty ? "—" : product.sku}  ·  Cost: ${_mmk.format(product.costPrice)} Ks',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stock <= product.minStock
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock: $stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stock <= product.minStock
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Draft Item Row (editable quantity + unit cost)
// ══════════════════════════════════════════════════════════════
class _DraftItemRow extends StatefulWidget {
  const _DraftItemRow({
    required this.item,
    required this.onQtyChanged,
    required this.onCostChanged,
    required this.onRemove,
  });
  final _DraftItem item;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onCostChanged;
  final VoidCallback onRemove;

  @override
  State<_DraftItemRow> createState() => _DraftItemRowState();
}

class _DraftItemRowState extends State<_DraftItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity.toStringAsFixed(0));
    _costCtrl = TextEditingController(
        text: widget.item.unitCost.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.item.productName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Quantity
              Expanded(
                child: _NumberField(
                  label: 'အရေအတွက်',
                  ctrl: _qtyCtrl,
                  onChanged: (v) {
                    final qty = double.tryParse(v) ?? 0;
                    if (qty > 0) widget.onQtyChanged(qty);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Unit cost
              Expanded(
                child: _NumberField(
                  label: 'တစ်ခု ဝယ်ကျ (Ks)',
                  ctrl: _costCtrl,
                  onChanged: (v) {
                    final cost = double.tryParse(v) ?? 0;
                    if (cost >= 0) widget.onCostChanged(cost);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('စုစုပေါင်း',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '${_mmk.format(widget.item.totalCost)} Ks',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Reusable numeric TextField
// ══════════════════════════════════════════════════════════════
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.ctrl,
    required this.onChanged,
  });
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Payment Panel (bottom bar of new purchase)
// ══════════════════════════════════════════════════════════════
class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.subtotal,
    required this.discountCtrl,
    required this.paidCtrl,
    required this.paymentStatus,
    required this.notesCtrl,
    required this.onStatusChanged,
    required this.onChanged,
    required this.total,
    required this.balance,
    required this.onSubmit,
  });

  final double subtotal;
  final TextEditingController discountCtrl;
  final TextEditingController paidCtrl;
  final PurchasePaymentStatus paymentStatus;
  final TextEditingController notesCtrl;
  final ValueChanged<PurchasePaymentStatus> onStatusChanged;
  final VoidCallback onChanged;
  final double total;
  final double balance;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Totals & Discount
          Row(
            children: [
              _TotalRow('စုစုပေါင်း (Subtotal)', subtotal),
              const SizedBox(width: 14),
              // Discount field
              SizedBox(
                width: 150,
                child: _NumberField(
                  label: 'လျှော့ပေး (Discount Ks)',
                  ctrl: discountCtrl,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 14),
              _TotalRow('ပေးရမည် (Total)', total,
                  color: AppColors.primary),
              const Spacer(),
              _TotalRow(
                'ကျန် (Balance)',
                balance,
                color: balance > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Payment status + paid amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Payment status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ငွေပေးချေမှု',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  SegmentedButton<PurchasePaymentStatus>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      selectedForegroundColor: AppColors.primary,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    segments: PurchasePaymentStatus.values
                        .map((s) => ButtonSegment(
                              value: s,
                              label: Text(s.shortLabel),
                            ))
                        .toList(),
                    selected: {paymentStatus},
                    onSelectionChanged: (sel) =>
                        onStatusChanged(sel.first),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Paid amount
              SizedBox(
                width: 160,
                child: _NumberField(
                  label: 'ပေးပြီးသည် (Paid Ks)',
                  ctrl: paidCtrl,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 3: Notes & Submit button
          Row(
            children: [
              // Notes
              Expanded(
                child: TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    hintText: 'မှတ်ချက် (optional)...',
                    hintStyle: const TextStyle(fontSize: 11),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(width: 14),

              // Submit button
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'ဝယ်ယူမှု မှတ်တမ်းတင်မည်',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.color});
  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          '${_mmk.format(amount)} Ks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Purchase History
// ══════════════════════════════════════════════════════════════
class _PurchaseHistoryTab extends ConsumerStatefulWidget {
  const _PurchaseHistoryTab();

  @override
  ConsumerState<_PurchaseHistoryTab> createState() =>
      _PurchaseHistoryTabState();
}

class _PurchaseHistoryTabState extends ConsumerState<_PurchaseHistoryTab> {
  String _search = '';
  String _branchFilter = 'all';
  PurchasePaymentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final livePurchases = purchaseState.purchases;
    final liveIds = livePurchases.map((p) => p.id).toSet();
    final baseline = kBaselinePurchases.where((p) => !liveIds.contains(p.id));
    final purchases = [...livePurchases, ...baseline];

    final filtered = purchases.where((p) {
      if (_branchFilter != 'all' && p.branchId != _branchFilter) return false;
      if (_statusFilter != null && p.paymentStatus != _statusFilter) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return p.purchaseNo.toLowerCase().contains(q) ||
            (p.vendorName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              // Search
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ဘောင်ချာ နံပါတ် / ကုန်သည် ရှာဖွေ...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              // Branch filter
              DropdownButton<String>(
                value: ['all', ...kBranches.keys].contains(_branchFilter) ? _branchFilter : 'all',
                underline: const SizedBox(),
                dropdownColor: AppColors.surfaceVariant,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('ဆိုင်ခွဲ — အားလုံး')),
                  ...kBranches.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      )),
                ],
                onChanged: (v) => setState(() => _branchFilter = v!),
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              // Status filter
              DropdownButton<PurchasePaymentStatus?>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ငွေပေးချေမှု — အားလုံး')),
                  ...PurchasePaymentStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.burmeseLabel),
                      )),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${filtered.length} ဘောင်ချာ',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // Table header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              SizedBox(width: 160, child: Text('ဘောင်ချာ နံပါတ်', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 120, child: Text('ရက်စွဲ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Text('ကုန်သည်', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 100, child: Text('ဆိုင်ခွဲ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 130, child: Text('ပေးရမည် (Total)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              SizedBox(width: 130, child: Text('ကျန် (Balance)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              SizedBox(width: 120, child: Text('ငွေပေးချေ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(branchesProvider.notifier).loadBranches(),
                ref.read(purchaseProvider.notifier).loadPurchases(),
                ref.read(vendorProvider.notifier).loadVendors(),
              ]);
            },
            child: purchaseState.isLoading && filtered.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'အဝယ်စာရင်းနှင့် ဘောက်ချာများ ရယူနေပါသည်...',
                      subMessage: 'Loading purchases from database...',
                      icon: Icons.receipt_long_rounded,
                    ),
                  )
                : filtered.isEmpty
                    ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 56,
                                  color: AppColors.textSecondary.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('ဝယ်ယူမှု မှတ်တမ်း မရှိသေးပါ',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) =>
                        _PurchaseHistoryRow(purchase: filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── History row ────────────────────────────────────────────────
class _PurchaseHistoryRow extends StatelessWidget {
  const _PurchaseHistoryRow({required this.purchase});
  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (purchase.paymentStatus) {
      PurchasePaymentStatus.paid    => AppColors.success,
      PurchasePaymentStatus.unpaid  => AppColors.error,
      PurchasePaymentStatus.partial => AppColors.warning,
    };

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => PurchaseDetailDialog(
          purchaseId: purchase.id,
          initialPurchase: purchase,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: Text(purchase.purchaseNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            SizedBox(
              width: 120,
              child: Text(_dateFmt.format(purchase.purchaseDate),
                  style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Text(
                purchase.vendorName ?? '— ကုန်သည်မဆိုင်',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(purchase.branchLabel,
                  style: const TextStyle(fontSize: 12)),
            ),
            SizedBox(
              width: 130,
              child: Text('${_mmk.format(purchase.totalAmount)} Ks',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            SizedBox(
              width: 130,
              child: Text(
                purchase.balanceDue > 0
                    ? '${_mmk.format(purchase.balanceDue)} Ks'
                    : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    color: purchase.balanceDue > 0
                        ? AppColors.warning
                        : AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 120,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    purchase.paymentStatus.burmeseLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Purchase detail dialog ─────────────────────────────────────
class PurchaseDetailDialog extends ConsumerWidget {
  const PurchaseDetailDialog({
    super.key,
    required this.purchaseId,
    this.initialPurchase,
  });
  final String purchaseId;
  final Purchase? initialPurchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchaseProvider).purchases;
    final purchase = purchases.where((p) => p.id == purchaseId).firstOrNull ?? initialPurchase;
    if (purchase == null) return const SizedBox.shrink();

    final statusColor = switch (purchase.paymentStatus) {
      PurchasePaymentStatus.paid    => AppColors.success,
      PurchasePaymentStatus.unpaid  => AppColors.error,
      PurchasePaymentStatus.partial => AppColors.warning,
    };

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    purchase.purchaseNo,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(purchase.paymentStatus.burmeseLabel,
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Info grid
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _InfoCell('ကုန်သည်', purchase.vendorName ?? '—'),
                      _InfoCell('ဆိုင်ခွဲ', purchase.branchLabel),
                      _InfoCell('ရက်စွဲ', _dateFmt.format(purchase.purchaseDate)),
                      _InfoCell('မှတ်ချက်', purchase.notes ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items table
                  const Row(
                    children: [
                      Expanded(child: Text('ပစ္စည်း', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      SizedBox(width: 80, child: Text('အရေ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      SizedBox(width: 120, child: Text('တစ်ခု Ks', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      SizedBox(width: 130, child: Text('စုစုပေါင်း Ks', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                  ),
                  const Divider(),
                  ...purchase.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 13))),
                        SizedBox(width: 80, child: Text(_qty.format(item.quantity), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                        SizedBox(width: 120, child: Text(_mmk.format(item.unitCost), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                        SizedBox(width: 130, child: Text(_mmk.format(item.totalCost), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      ],
                    ),
                  )),
                  const Divider(),

                  // Totals
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _SummaryLine('Subtotal', purchase.subtotal),
                      _SummaryLine('Discount', purchase.discount, color: AppColors.warning),
                      _SummaryLine('Total', purchase.totalAmount, color: AppColors.primary, large: true),
                      _SummaryLine('Paid', purchase.paidAmount, color: AppColors.success),
                      _SummaryLine('Balance Due', purchase.balanceDue,
                          color: purchase.balanceDue > 0 ? AppColors.error : AppColors.textSecondary),
                    ],
                  ),

                  // Settle Debt Action Card
                  const SizedBox(height: 16),
                  if (purchase.balanceDue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: AppColors.warning, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ပေးချေရန် ကြွေးကျန် (Outstanding Balance)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_mmk.format(purchase.balanceDue)} Ks ကျန်ရှိပါသည်',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => showPurchasePaymentDialog(context, ref, purchase),
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: const Text('ငွေချေမည် (Make Payment)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'ဤဘောင်ချာအတွက် ငွေအကြေ ပေးချေပြီးဖြစ်ပါသည် (Fully Paid)',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showPurchasePaymentDialog(BuildContext context, WidgetRef ref, Purchase purchase) {
  final amountCtrl = TextEditingController(text: purchase.balanceDue.toStringAsFixed(0));
  final noteCtrl = TextEditingController();
  String paymentMethod = 'Cash';

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ကြွေးကျန် ပေးချေလွှာ (Settle Purchase Payment)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('${purchase.purchaseNo} — ${purchase.vendorName ?? 'ကုန်သည်မရှိ'}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance summary card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('စုစုပေါင်း (Total)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${_mmk.format(purchase.totalAmount)} Ks',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('ပေးပြီး (Paid)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${_mmk.format(purchase.paidAmount)} Ks',
                            style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('လက်ကျန်ကြွေး (Due)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${_mmk.format(purchase.balanceDue)} Ks',
                            style: const TextStyle(fontSize: 14, color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment amount field
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                decoration: InputDecoration(
                  labelText: 'ပေးချေမည့် ပမာဏ (Payment Amount Ks) *',
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: AppColors.primary),
                  suffixText: 'Ks',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),

              // Quick chip for full settlement
              Align(
                alignment: Alignment.centerRight,
                child: ActionChip(
                  avatar: const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
                  label: Text('ငွေကြေပေးချေမည် (${_mmk.format(purchase.balanceDue)} Ks)',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  onPressed: () {
                    amountCtrl.text = purchase.balanceDue.toStringAsFixed(0);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Payment method
              Text('ငွေပေးချေသည့် နည်းလမ်း (Payment Method)',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Cash', 'KPay', 'CB Pay', 'AYA Pay', 'WavePay', 'Bank Transfer'].map((m) {
                  final isSelected = paymentMethod == m;
                  return ChoiceChip(
                    label: Text(m, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    onSelected: (val) {
                      if (val) setDialogState(() => paymentMethod = m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'ငွေပေးချေမှု မှတ်ချက် (Payment Note / Reference - Optional)',
                  hintText: 'ဥပမာ: KPay Trx ID: 1049283928',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton.icon(
            onPressed: () async {
              final rawAmount = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
              if (rawAmount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ ပေးချေမည့် ငွေပမာဏ မှန်ကန်စွာ ထည့်သွင်းပါ'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final fullNote = noteCtrl.text.trim().isNotEmpty
                  ? '($paymentMethod) ${noteCtrl.text.trim()}'
                  : '($paymentMethod)';

              final ok = await ref.read(purchaseProvider.notifier).recordPayment(
                    purchaseId: purchase.id,
                    paymentAmount: rawAmount,
                    note: fullNote,
                  );

              if (!ok || !ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!context.mounted) return;

              final updated = ref.read(purchaseProvider).purchases
                  .firstWhere((p) => p.id == purchase.id, orElse: () => purchase);

              final isFullyPaid = updated.paymentStatus == PurchasePaymentStatus.paid;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFullyPaid
                        ? '✅ ${_mmk.format(rawAmount)} Ks ပေးချေပြီး — ဘောင်ချာ ငွေကြေ (Paid) ဖြစ်သွားပါပြီ'
                        : '✅ ${_mmk.format(rawAmount)} Ks ပေးချေပြီး — ကျန်ရှိငွေ ${_mmk.format(updated.balanceDue)} Ks',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('အတည်ပြု ပေးချေမည် (Confirm Payment)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.amount, {this.color, this.large = false});
  final String label;
  final double amount;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(
          '${_mmk.format(amount)} Ks',
          style: TextStyle(
            fontSize: large ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Internal draft item model ─────────────────────────────────
class _DraftItem {
  const _DraftItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;

  double get totalCost => quantity * unitCost;

  _DraftItem copyWith({double? quantity, double? unitCost}) => _DraftItem(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost ?? this.unitCost,
      );
}
