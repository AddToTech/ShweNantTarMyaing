// ============================================================
// Branch Management View (CRUD)
// Allows creating, viewing, editing, and deleting shop branches
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../domain/models/product.dart';
import '../../../shared/widgets/loading_view.dart';

class BranchManagementView extends ConsumerStatefulWidget {
  const BranchManagementView({super.key});

  @override
  ConsumerState<BranchManagementView> createState() => _BranchManagementViewState();
}

class _BranchManagementViewState extends ConsumerState<BranchManagementView> {
  final _searchCtrl = TextEditingController();
  bool _showInactive = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditBranchDialog({Branch? branch}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditBranchDialog(branchToEdit: branch),
    );
  }

  void _confirmDeleteBranch(Branch branch) {
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
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ဆိုင်ခွဲ ဖျက်သိမ်းမည်လား?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ဆိုင်ခွဲအမည်: "${branch.name}"',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            if (branch.address != null && branch.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'လိပ်စာ: ${branch.address}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'အကယ်၍ ဤဆိုင်ခွဲတွင် အရောင်း၊ ကုန်ပစ္စည်းလက်ကျန် သို့မဟုတ် ဝန်ထမ်းစာရင်းများ ရှိနေပါက စာရင်းဇယားများ မပျက်စီးစေရန် ဆိုင်ခွဲကို ပိတ်သိမ်း (Deactivate) သာ ပြုလုပ်ပေးမည် ဖြစ်ပါသည်။',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မဖျက်ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(branchListNotifierProvider.notifier).deleteBranch(branch.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ဖျက်သိမ်းမည် (Confirm)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBranches = ref.watch(branchListNotifierProvider);
    final isBranchLoading = ref.watch(branchLoadingProvider);
    final search = _searchCtrl.text.trim().toLowerCase();

    final filteredBranches = allBranches.where((b) {
      if (!_showInactive && !b.isActive) return false;
      if (search.isEmpty) return true;
      final name = b.name.toLowerCase();
      final address = (b.address ?? '').toLowerCase();
      final phone = (b.phone ?? '').toLowerCase();
      return name.contains(search) || address.contains(search) || phone.contains(search);
    }).toList();

    final totalCount = allBranches.length;
    final activeCount = allBranches.where((b) => b.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return RefreshIndicator(
      onRefresh: () => ref.read(branchListNotifierProvider.notifier).loadBranches(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Summary Cards ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'စုစုပေါင်း ဆိုင်ခွဲများ',
                    count: '$totalCount ခု',
                    icon: Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'ဖွင့်လှစ်ထားသော ဆိုင်ခွဲများ',
                    count: '$activeCount ခု',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'ပိတ်သိမ်းထားသော ဆိုင်ခွဲများ',
                    count: '$inactiveCount ခု',
                    icon: Icons.pause_circle_outline_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Toolbar & Actions ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'ဆိုင်ခွဲအမည်၊ လိပ်စာ သို့မဟုတ် ဖုန်းဖြင့် ရှာဖွေပါ...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Show Inactive Toggle
                  InkWell(
                    onTap: () => setState(() => _showInactive = !_showInactive),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _showInactive ? AppColors.surfaceVariant : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showInactive ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showInactive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 16,
                            color: _showInactive ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ပိတ်ထားသောဆိုင်ခွဲများ ပြသရန်',
                            style: TextStyle(
                              color: _showInactive ? AppColors.textPrimary : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: _showInactive ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Reload Button
                  IconButton(
                    tooltip: 'အချက်အလက် ပြန်လည်ရယူရန် (Reload)',
                    onPressed: () => ref.read(branchListNotifierProvider.notifier).loadBranches(),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),

                  // + Add Branch Button
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditBranchDialog(),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text(
                      '+ ဆိုင်ခွဲအသစ် ထည့်သွင်းမည်',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Branch List Cards ──────────────────────────────────────
            if (isBranchLoading && filteredBranches.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingView(
                    message: 'ဆိုင်ခွဲစာရင်းများ ရယူနေပါသည်...',
                    subMessage: 'Loading shop branches...',
                    icon: Icons.storefront_rounded,
                  ),
                ),
              )
            else if (filteredBranches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'ဆိုင်ခွဲ မရှိသေးပါ သို့မဟုတ် ရှာဖွေမှုနှင့် ကိုက်ညီမှုမရှိပါ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ညာဘက်ထိပ်ရှိ "+ ဆိုင်ခွဲအသစ် ထည့်သွင်းမည်" ကိုနှိပ်၍ ဆိုင်ခွဲအသစ် ဖွင့်လှစ်နိုင်ပါသည်။',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 520,
                  mainAxisExtent: 175,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredBranches.length,
                itemBuilder: (context, index) {
                  final branch = filteredBranches[index];
                  return _buildBranchCard(branch);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: branch.isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Status Badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: branch.isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🏢',
                  style: TextStyle(
                    fontSize: 20,
                    color: branch.isActive ? null : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: TextStyle(
                        color: branch.isActive ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${branch.id.length > 8 ? "${branch.id.substring(0, 8)}..." : branch.id}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: branch.isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: branch.isActive ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      branch.isActive ? 'ဖွင့်လှစ်ထား' : 'ပိတ်သိမ်းထား',
                      style: TextStyle(
                        color: branch.isActive ? const Color(0xFF10B981) : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Details: Address & Phone
          if (branch.address != null && branch.address!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branch.address!,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (branch.phone != null && branch.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branch.phone!,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Divider(height: 12, color: AppColors.border),

          // Actions: Edit and Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAddEditBranchDialog(branch: branch),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('ပြင်ဆင်မည် (Edit)', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDeleteBranch(branch),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('ဖျက်မည် (Delete)', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Add / Edit Branch Dialog
// ============================================================

class _AddEditBranchDialog extends ConsumerStatefulWidget {
  const _AddEditBranchDialog({this.branchToEdit});

  final Branch? branchToEdit;

  @override
  ConsumerState<_AddEditBranchDialog> createState() => _AddEditBranchDialogState();
}

class _AddEditBranchDialogState extends ConsumerState<_AddEditBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branchToEdit;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _addressCtrl = TextEditingController(text: b?.address ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(branchListNotifierProvider.notifier);

    if (widget.branchToEdit == null) {
      // Create new
      final created = await notifier.addBranch(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        isActive: _isActive,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (created != null) Navigator.of(context).pop();
      }
    } else {
      // Update existing
      final ok = await notifier.updateBranch(
        widget.branchToEdit!.id,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        isActive: _isActive,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branchToEdit != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🏢', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'ဆိုင်ခွဲ ပြင်ဆင်ခြင်း (Edit Branch)' : 'ဆိုင်ခွဲသစ် ဖွင့်လှစ်ခြင်း (New Branch)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEdit ? 'ဆိုင်ခွဲအချက်အလက်များကို မွမ်းမံပါ' : 'ဆိုင်ခွဲအချက်အလက်များကို ဖြည့်သွင်းပါ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                Text('ဆိုင်ခွဲအမည် (Branch Name) *',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ဥပမာ - SitePyoe Branch A (Mingaladon)',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ဆိုင်ခွဲအမည် ထည့်သွင်းပါ' : null,
                ),
                const SizedBox(height: 14),

                // Address
                Text('တည်နေရာ / လိပ်စာ (Address)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressCtrl,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ဥပမာ - အမှတ် (၁၂)၊ ပြည်လမ်း၊ မင်္ဂလာဒုံမြို့နယ်၊ ရန်ကုန်',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone
                Text('ဆက်သွယ်ရန်ဖုန်း (Phone)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '09-123456789',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ဆိုင်ခွဲ ဖွင့်လှစ်ထားခြင်း',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                          Text('ပိတ်ထားပါက POS နှင့် အရောင်းစာရင်းတွင် အသစ်ရွေးချယ်၍ မရတော့ပါ',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text('မလုပ်ဆောင်ပါ (Cancel)', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEdit ? 'သိမ်းဆည်းမည် (Save)' : 'ထည့်သွင်းမည် (Create)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

