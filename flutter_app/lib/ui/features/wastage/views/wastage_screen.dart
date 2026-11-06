import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../view_models/wastage_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

class WastageScreen extends ConsumerStatefulWidget {
  const WastageScreen({super.key});

  @override
  ConsumerState<WastageScreen> createState() => _WastageScreenState();
}

class _WastageScreenState extends ConsumerState<WastageScreen> {
  String _selectedBranchId = 'branch_a';
  MockProduct? _selectedProduct;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  WastageReasonOption _selectedReason = WastageReasonOption.deadWithered;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = ref.read(defaultBranchProvider);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWastage() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဦးစွာ ကုန်ပစ္စည်းတစ်ခု ရွေးချယ်ပေးပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အရေအတွက်ကို သုညထက်ကြီးသော ဂဏန်းဖြင့် ထည့်သွင်းပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final product = _selectedProduct!;
    final currentStock = ref.read(inventoryProvider).getStock(_selectedBranchId, product.id);
    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('အရေအတွက် ($qty) သည် လက်ကျန်ရှိသော အရေအတွက် ($currentStock) ထက် မကျော်လွန်နိုင်ပါ။'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(wastageProvider.notifier).recordWastage(
          branchId: _selectedBranchId,
          product: product,
          quantity: qty,
          reason: _selectedReason,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ပျက်စီး/သေဆုံး မှတ်တမ်းတင်ပြီး: $qty × ${product.name} ကို စာရင်းမှ နုတ်ယူပြီးပါပြီ။',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _selectedProduct = null;
        _qtyCtrl.text = '1';
        _notesCtrl.clear();
      });
    }
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ProductPickerSheet(
          branchId: _selectedBranchId,
          onSelect: (product) {
            setState(() {
              _selectedProduct = product;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(defaultBranchProvider, (_, next) {
      if (mounted) setState(() => _selectedBranchId = next);
    });
    final currencyFmt = NumberFormat('#,###');
    final wastageState = ref.watch(wastageProvider);
    final invState = ref.watch(inventoryProvider);

    final currentStock = _selectedProduct != null
        ? invState.getStock(_selectedBranchId, _selectedProduct!.id)
        : 0;

    final parsedQty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final estimatedLoss = _selectedProduct != null
        ? parsedQty * _selectedProduct!.costPrice
        : 0.0;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ── Top Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'အပင်သေဆုံးနှင့် ပျက်စီးမှု မှတ်တမ်း (Wastage Tracking)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'အပင်သေဆုံး / ပျက်စီးမှု မှတ်တမ်း (Stock Deductions)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
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
                      value: kBranches.containsKey(_selectedBranchId)
                          ? _selectedBranchId
                          : (kBranches.keys.firstOrNull ?? _selectedBranchId),
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
                        if (val != null) {
                          setState(() {
                            _selectedBranchId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Dual-Pane Body ────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Form (40% width) ─────────────────────────
                SizedBox(
                  width: 420,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.border)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ပျက်စီး/သေဆုံး မှတ်တမ်းအသစ် ရေးသွင်းခြင်း',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Product Selector Card
                          Text(
                            'ကုန်ပစ္စည်း / အပင်',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _showProductPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedProduct != null
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: _selectedProduct == null
                                  ? Row(
                                      children: [
                                        Icon(Icons.search_rounded,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'အပင် သို့မဟုတ် ပန်းအိုး ရှာဖွေရွေးချယ်ပါ...',
                                            style: TextStyle(
                                                color: AppColors.textMuted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_ios_rounded,
                                            size: 14, color: AppColors.textMuted),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: ProductAvatar(
                                            imageEmoji: _selectedProduct!.imageEmoji,
                                            customImagePath: _selectedProduct!.customImagePath,
                                            size: 26,
                                            fontSize: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedProduct!.name,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: currentStock <=
                                                              _selectedProduct!.minStock
                                                          ? AppColors.error
                                                              .withValues(alpha: 0.2)
                                                          : AppColors.primary
                                                              .withValues(alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'လက်ကျန်: $currentStock ခု',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: currentStock <=
                                                                _selectedProduct!
                                                                    .minStock
                                                            ? AppColors.error
                                                            : AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'အရင်း: ${currencyFmt.format(_selectedProduct!.costPrice)} Ks',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close_rounded,
                                              size: 18, color: AppColors.textMuted),
                                          onPressed: () => setState(() =>
                                              _selectedProduct = null),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Quantity & Reason Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Field
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'အရေအတွက်',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppColors.surface,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: AppColors.border),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Reason Dropdown
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ပျက်စီးရသည့် အကြောင်းရင်း',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<WastageReasonOption>(
                                          isExpanded: true,
                                          value: _selectedReason,
                                          dropdownColor: AppColors.surfaceVariant,
                                          items: WastageReasonOption.values.map((r) {
                                            return DropdownMenuItem(
                                              value: r,
                                              child: Row(
                                                children: [
                                                  Text(r.emoji),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '${r.burmeseLabel} (${r.label})',
                                                      style: TextStyle(
                                                        color: AppColors.textPrimary,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() =>
                                                  _selectedReason = val);
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

                          const SizedBox(height: 16),

                          // Notes Field
                          Text(
                            'မှတ်ချက် / အသေးစိတ် အကြောင်းပြချက်',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'ဥပမာ - စင်နံပါတ် ၂ မှ ပန်းအိုးပြုတ်ကျကွဲခြင်း၊ အမြစ်ပုပ်ခြင်း...',
                              hintStyle:
                                  TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Live Financial Impact Preview
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ဆုံးရှုံးမှုတန်ဖိုး (FINANCIAL LOSS)',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'အရင်းဆုံးရှုံးမှု:',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '-${currencyFmt.format(estimatedLoss)} Ks',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _selectedProduct == null ||
                                      currentStock <= 0
                                  ? null
                                  : _submitWastage,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              label: const Text(
                                'စာရင်းမှနုတ်ပြီး မှတ်တမ်းတင်မည်',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.surfaceVariant,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Right: Wastage Audit Log (60% width) ───────────
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Audit Header & Stat Badges
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ပျက်စီး/သေဆုံးမှု စစ်ဆေးရေးမှတ်တမ်း (Audit Log)',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'အပင်သေဆုံးခြင်းနှင့် ပစ္စည်းပျက်စီးမှုကြောင့် ဆုံးရှုံးမှုစာရင်း',
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Total Loss badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.trending_down_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'စုစုပေါင်း ဆုံးရှုံးမှုတန်ဖိုး',
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        '${currencyFmt.format(wastageState.totalLoss)} Ks',
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Reason chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _ReasonFilterChip(
                              label: 'အားလုံး (All)',
                              selected:
                                  wastageState.selectedReasonFilter == null,
                              onTap: () => ref
                                  .read(wastageProvider.notifier)
                                  .setReasonFilter(null),
                            ),
                            ...WastageReasonOption.values.map((r) {
                              return _ReasonFilterChip(
                                label: '${r.emoji} ${r.burmeseLabel}',
                                selected:
                                    wastageState.selectedReasonFilter == r,
                                onTap: () => ref
                                    .read(wastageProvider.notifier)
                                    .setReasonFilter(r),
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Audit Log List
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            onRefresh: () async {
                              await Future.wait([
                                ref.read(branchesProvider.notifier).loadBranches(),
                                ref.read(wastageProvider.notifier).loadWastage(),
                                ref.read(catalogProvider.notifier).loadProducts(),
                              ]);
                            },
                            child: wastageState.isLoading && wastageState.filteredEntries.isEmpty
                                ? const Center(
                                    child: AppLoadingView(
                                      message: 'ပျက်စီး/သေဆုံး မှတ်တမ်းများ ရယူနေပါသည်...',
                                      subMessage: 'Loading wastage records...',
                                      icon: Icons.eco_rounded,
                                    ),
                                  )
                                : wastageState.filteredEntries.isEmpty
                                    ? CustomScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.inventory_2_outlined,
                                                  size: 48,
                                                  color: AppColors.textMuted
                                                      .withValues(alpha: 0.5)),
                                              const SizedBox(height: 10),
                                              Text(
                                                'ရွေးချယ်ထားသော အကြောင်းရင်းအတွက် ပျက်စီးမှုမှတ်တမ်း မရှိပါ',
                                                style: TextStyle(
                                                    color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount:
                                        wastageState.filteredEntries.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final entry =
                                          wastageState.filteredEntries[idx];
                                      return _WastageLogCard(entry: entry);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonFilterChip extends StatelessWidget {
  const _ReasonFilterChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WastageLogCard extends StatelessWidget {
  const _WastageLogCard({required this.entry});
  final WastageEntry entry;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reason Icon circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(entry.reason.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.productName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '-${currencyFmt.format(entry.totalCostLoss)} Ks',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: -${entry.quantity}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${entry.reason.label} (${entry.reason.burmeseLabel})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '• ${entry.branchName}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (entry.notes != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${entry.notes}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${entry.id} • ${dateFmt.format(entry.recordedAt)}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet modal for selecting products
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet({
    required this.branchId,
    required this.onSelect,
  });

  final String branchId;
  final ValueChanged<MockProduct> onSelect;

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final invState = ref.watch(inventoryProvider);
    final catalog = ref.watch(catalogProvider);

    final filtered = catalog.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode != null && p.barcode!.contains(q));
    }).toList();

    return SizedBox(
      height: 520,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'ပျက်စီး/သေဆုံး မှတ်တမ်းတင်မည့် ပစ္စည်းရွေးချယ်ပါ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'အပင်အမည်၊ ပန်းအိုး၊ SKU သို့မဟုတ် ဘားကုဒ် ရှာဖွေပါ...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, idx) {
                  final p = filtered[idx];
                  final stock = invState.getStock(widget.branchId, p.id);
                  return ListTile(
                    leading: ProductAvatar(
                      imageEmoji: p.imageEmoji,
                      customImagePath: p.customImagePath,
                      size: 28,
                      fontSize: 24,
                    ),
                    title: Text(
                      p.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'အရင်း: ${currencyFmt.format(p.costPrice)} Ks  •  ရောင်းဈေး: ${currencyFmt.format(p.salePrice)} Ks',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: stock <= p.minStock
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'လက်ကျန်: $stock ခု',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stock <= p.minStock ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ),
                    onTap: () => widget.onSelect(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
