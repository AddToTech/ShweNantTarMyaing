import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../view_models/transfer_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Create Transfer State
  String _fromBranch = 'branch_a';
  String _toBranch = 'branch_b';
  final List<_DraftTransferItem> _draftItems = [];
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addItemToDraft(MockProduct product) {
    final existingIdx = _draftItems.indexWhere((i) => i.product.id == product.id);
    final invState = ref.read(inventoryProvider);
    final available = invState.getStock(_fromBranch, product.id);

    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} သည် ${_getBranchName(_fromBranch)} တွင် ပစ္စည်းပြတ်နေပါသည်။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      if (existingIdx >= 0) {
        if (_draftItems[existingIdx].quantity < available) {
          _draftItems[existingIdx].quantity++;
        }
      } else {
        _draftItems.add(_DraftTransferItem(product: product, quantity: 1));
      }
    });
  }

  Future<void> _submitTransfer() async {
    if (_fromBranch == _toBranch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('လွှဲပြောင်းမည့်ဆိုင်ခွဲ နှင့် လက်ခံမည့်ဆိုင်ခွဲ မတူညီရပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('လွှဲပြောင်းရန် ပစ္စည်း အနည်းဆုံး (၁) ခု ထည့်သွင်းပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final items = _draftItems.map((d) {
      return TransferItemRecord(
        productId: d.product.id,
        productName: d.product.name,
        quantity: d.quantity,
        unitCost: d.product.costPrice,
        category: d.product.category,
        originType: d.product.originType,
      );
    }).toList();

    final count = _draftItems.length;
    final success = await ref.read(transferProvider.notifier).createTransfer(
          fromBranchId: _fromBranch,
          toBranchId: _toBranch,
          items: items,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'လွှဲပြောင်းဘောက်ချာ ပြုလုပ်ပြီးပါပြီ! $count မျိုး လမ်းခရီးသို့ လွှဲပြောင်းပို့ဆောင်နေပါသည်။',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _draftItems.clear();
        _notesCtrl.clear();
      });
      _tabController.animateTo(0); // Switch to vouchers list
    }
  }

  String _getBranchName(String id) => kBranches[id] ?? id;

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ဆိုင်ခွဲအချင်းချင်း ပစ္စည်းလွှဲပြောင်းမှု (Branch Transfers)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ဆိုင်ခွဲအချင်းချင်း ပစ္စည်းလက်ကျန် အလွှဲအပြောင်း စီမံခန့်ခွဲမှု',
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
                // Tab switcher
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: AppColors.textOnPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'လွှဲပြောင်းမှတ်တမ်းများ (Vouchers)'),
                      Tab(text: '+ လွှဲပြောင်းမှုအသစ် ပြုလုပ်မည်'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Vouchers List View
                const _VouchersListView(),

                // 2. Create Transfer View
                _buildCreateTransferView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTransferView() {
    final currencyFmt = NumberFormat('#,###');
    final invState = ref.watch(inventoryProvider);
    final catalog = ref.watch(catalogProvider);

    final totalQuantity =
        _draftItems.fold(0, (sum, item) => sum + item.quantity);
    final totalCost = _draftItems.fold(
        0.0, (sum, item) => sum + (item.quantity * item.product.costPrice));

    return Row(
      children: [
        // ── Left: Source / Dest & Item Builder (50% width) ───
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch routing card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Source Branch
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'မူရင်းဆိုင်ခွဲ (မှ)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: kBranches.containsKey(_fromBranch)
                                      ? _fromBranch
                                      : (kBranches.keys.firstOrNull ?? _fromBranch),
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceVariant,
                                  items: kBranches.entries.map((e) {
                                    return DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _fromBranch = val;
                                        _draftItems.clear(); // Reset items on branch switch
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow indicator
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primary, size: 24),
                      ),

                      // Destination Branch
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'လက်ခံမည့်ဆိုင်ခွဲ (သို့)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: kBranches.containsKey(_toBranch)
                                      ? _toBranch
                                      : (kBranches.keys.length > 1
                                          ? kBranches.keys.elementAt(1)
                                          : (kBranches.keys.firstOrNull ?? _toBranch)),
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceVariant,
                                  items: kBranches.entries.map((e) {
                                    return DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _toBranch = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'လွှဲပြောင်းမည့် ကုန်ပစ္စည်းများ ရွေးချယ်ပါ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Product catalog list to pick from
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      await Future.wait([
                        ref.read(branchesProvider.notifier).loadBranches(),
                        ref.read(catalogProvider.notifier).loadProducts(),
                        ref.read(transferProvider.notifier).loadTransfers(),
                      ]);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: catalog.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final p = catalog[idx];
                        final available = invState.getStock(_fromBranch, p.id);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              ProductAvatar(
                                imageEmoji: p.imageEmoji,
                                customImagePath: p.customImagePath,
                                size: 26,
                                fontSize: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'အရင်း: ${currencyFmt.format(p.costPrice)} Ks  •  လက်ကျန်: $available',
                                      style: TextStyle(
                                        color: available <= p.minStock
                                            ? AppColors.warning
                                            : AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    available > 0 ? () => _addItemToDraft(p) : null,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('ထည့်မည်',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textOnPrimary,
                                  disabledBackgroundColor: AppColors.border,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
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
            ),
          ),
        ),

        // ── Right: Draft Items & Dispatch Summary (50% width) ─
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'လွှဲပြောင်းမည့် ပစ္စည်းစာရင်း (Manifest)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_draftItems.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _draftItems.clear()),
                        child: const Text('အားလုံးဖျက်မည်',
                            style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Manifest table
                Expanded(
                  child: _draftItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'No items added to this transfer yet.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select products from the left to include in the voucher.',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _draftItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final draft = _draftItems[idx];
                            final maxStock = invState.getStock(
                                _fromBranch, draft.product.id);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  ProductAvatar(
                                    imageEmoji: draft.product.imageEmoji,
                                    customImagePath: draft.product.customImagePath,
                                    size: 24,
                                    fontSize: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          draft.product.name,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Cost: ${currencyFmt.format(draft.product.costPrice)} Ks • Line: ${currencyFmt.format(draft.quantity * draft.product.costPrice)} Ks',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Stepper
                                  IconButton(
                                    icon: Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 20,
                                        color: AppColors.textSecondary),
                                    onPressed: () {
                                      setState(() {
                                        if (draft.quantity > 1) {
                                          draft.quantity--;
                                        } else {
                                          _draftItems.removeAt(idx);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    '${draft.quantity}',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 20,
                                        color: AppColors.primary),
                                    onPressed: () {
                                      if (draft.quantity < maxStock) {
                                        setState(() => draft.quantity++);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Cannot exceed available stock ($maxStock).'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesCtrl,
                  style:
                      TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'လွှဲပြောင်းမှုမှတ်ချက် / ယာဉ်မောင်း / ကားနံပါတ် / အကြောင်းပြချက်...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Totals & Submit
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'စုစုပေါင်း: $totalQuantity ခု',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'တန်ဖိုး: ${currencyFmt.format(totalCost)} Ks',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed:
                            _draftItems.isEmpty ? null : _submitTransfer,
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text(
                          'ပစ္စည်းထုတ်ယူပြီး ပို့ဆောင်မည်',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          disabledBackgroundColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftTransferItem {
  _DraftTransferItem({required this.product, required this.quantity});
  final MockProduct product;
  int quantity;
}

/// Vouchers List View (In-Transit & Received)
class _VouchersListView extends ConsumerWidget {
  const _VouchersListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferState = ref.watch(transferProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: 'ဘောက်ချာအားလုံး (All)',
                    selected: transferState.selectedStatusFilter == null,
                    onTap: () => ref
                        .read(transferProvider.notifier)
                        .setStatusFilter(null),
                  ),
                  _FilterChip(
                    label: '🚚 လမ်းခရီးတွင် (In-Transit)',
                    selected: transferState.selectedStatusFilter ==
                        TransferVoucherStatus.inTransit,
                    onTap: () => ref
                        .read(transferProvider.notifier)
                        .setStatusFilter(TransferVoucherStatus.inTransit),
                  ),
                  _FilterChip(
                    label: '✅ လက်ခံပြီး (Received)',
                    selected: transferState.selectedStatusFilter ==
                        TransferVoucherStatus.received,
                    onTap: () => ref
                        .read(transferProvider.notifier)
                        .setStatusFilter(TransferVoucherStatus.received),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vouchers list
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await Future.wait([
                  ref.read(branchesProvider.notifier).loadBranches(),
                  ref.read(transferProvider.notifier).loadTransfers(),
                  ref.read(catalogProvider.notifier).loadProducts(),
                ]);
              },
              child: transferState.isLoading && transferState.filteredVouchers.isEmpty
                  ? const Center(
                      child: AppLoadingView(
                        message: 'ဆိုင်ခွဲလွှဲပြောင်း မှတ်တမ်းများ ရယူနေပါသည်...',
                        subMessage: 'Loading transfer records...',
                        icon: Icons.swap_horiz_rounded,
                      ),
                    )
                  : transferState.filteredVouchers.isEmpty
                      ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_shipping_outlined,
                                    size: 48,
                                    color:
                                        AppColors.textMuted.withValues(alpha: 0.5)),
                                const SizedBox(height: 10),
                                Text(
                                  'လွှဲပြောင်းမှု ဘောက်ချာမှတ်တမ်း မရှိပါ',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: transferState.filteredVouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final voucher = transferState.filteredVouchers[idx];
                        return _VoucherCard(voucher: voucher);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VoucherCard extends ConsumerWidget {
  const _VoucherCard({required this.voucher});
  final TransferVoucher voucher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final isInTransit = voucher.status == TransferVoucherStatus.inTransit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInTransit
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  voucher.id,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Route
              Expanded(
                child: Text(
                  '${voucher.fromBranchName} ➔ ${voucher.toBranchName}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInTransit
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isInTransit ? AppColors.warning : AppColors.primary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInTransit
                          ? Icons.local_shipping_rounded
                          : Icons.check_circle_rounded,
                      size: 14,
                      color:
                          isInTransit ? AppColors.warning : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      voucher.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isInTransit ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Items Preview
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: voucher.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.productName} × ${item.quantity}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),

          if (voucher.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${voucher.notes}',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'လွှဲပြောင်းချိန်: ${dateFmt.format(voucher.createdAt)} • စုစုပေါင်းတန်ဖိုး: ${currencyFmt.format(voucher.totalValue)} Ks',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isInTransit)
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await ref
                        .read(transferProvider.notifier)
                        .receiveTransfer(voucher.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ဘောက်ချာ ${voucher.id} ကို လက်ခံပြီးပါပြီ! ${voucher.toBranchName} တွင် စာရင်းထည့်သွင်းပြီးပါပြီ။',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 16),
                  label: const Text(
                    'ပစ္စည်းလက်ခံအတည်ပြုမည်',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (voucher.receivedAt != null)
                Text(
                  'လက်ခံရရှိချိန်: ${dateFmt.format(voucher.receivedAt!)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
