// ============================================================
// Plant Origin Management View (CRUD)
// Allows viewing, adding, editing, and managing plant origins
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/models/plant_origin.dart';
import '../../../shared/widgets/loading_view.dart';
import '../view_models/plant_origin_notifier.dart';

class PlantOriginManagementView extends ConsumerStatefulWidget {
  const PlantOriginManagementView({super.key});

  @override
  ConsumerState<PlantOriginManagementView> createState() =>
      _PlantOriginManagementViewState();
}

class _PlantOriginManagementViewState
    extends ConsumerState<PlantOriginManagementView> {
  final _searchCtrl = TextEditingController();
  bool _showInactive = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditOriginDialog({PlantOrigin? origin}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditOriginDialog(originToEdit: origin),
    );
  }

  void _confirmDeleteOrigin(PlantOrigin origin) {
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
            Expanded(
              child: Text(
                'မူရင်းဒေသ ဖျက်သိမ်းမည်လား?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '"${origin.name}" ကို ဖျက်သိမ်းရန် သေချာပါသလား?\n\nမှတ်ချက်: ဤဒေသဖြင့် သတ်မှတ်ထားသော ပစ္စည်းများ ရှိနေပါက စာရင်းမှ လုံးဝမပျက်ဘဲ ပိတ်ထားရုံ (Deactivate) သာ ပြုလုပ်ပေးပါမည်။',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(plantOriginProvider.notifier)
                  .deleteOrigin(origin.id);
              if (mounted) {
                if (ok) {
                  AppToast.showSuccess('မူရင်းဒေသ ဖျက်သိမ်း/ပိတ်သိမ်းပြီးပါပြီ');
                } else {
                  AppToast.showError('ဖျက်သိမ်းမှု မအောင်မြင်ပါ');
                }
              }
            },
            child: const Text('ဖျက်သိမ်းမည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origins = ref.watch(plantOriginProvider);
    final isLoading = ref.watch(plantOriginLoadingProvider);

    final filtered = origins.where((o) {
      if (!_showInactive && !o.isActive) return false;
      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        final match = o.name.toLowerCase().contains(q) ||
            (o.code != null && o.code!.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();

    final totalCount = origins.length;
    final activeCount = origins.where((o) => o.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return Column(
      children: [
        // ── KPI Summary Cards ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'စုစုပေါင်း မူရင်းဒေသများ',
                  value: '$totalCount ခု',
                  icon: Icons.public_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'အသုံးပြုနေသော ဒေသများ',
                  value: '$activeCount ခု',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'ပိတ်ထားသော ဒေသများ',
                  value: '$inactiveCount ခု',
                  icon: Icons.pause_circle_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // ── Action Bar: Search, Show Inactive, Refresh, Add ───────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'မူရင်းဒေသအမည် သို့မဟုတ် ကုဒ်ဖြင့် ရှာဖွေပါ...',
                      hintStyle:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter Inactive Toggle
              FilterChip(
                label: const Text('ပိတ်ထားသောဒေသများ ပြသရန်'),
                selected: _showInactive,
                onSelected: (val) => setState(() => _showInactive = val),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _showInactive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight:
                      _showInactive ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _showInactive
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Reload Button
              IconButton(
                onPressed: () =>
                    ref.read(plantOriginProvider.notifier).loadOrigins(),
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textSecondary,
                tooltip: 'ပြန်လည်ရယူပါ (Refresh)',
              ),
              const SizedBox(width: 8),

              // Add Origin Button
              ElevatedButton.icon(
                onPressed: () => _showAddEditOriginDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('မူရင်းဒေသအသစ် ထည့်သွင်းမည်'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Origins Grid / List ───────────────────────────────────
        Expanded(
          child: isLoading && origins.isEmpty
              ? const Center(child: AppLoadingView())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public_off_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'မူရင်းဒေသ မတွေ့ရှိပါ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'အသစ်ထည့်သွင်းရန် "မူရင်းဒေသအသစ် ထည့်သွင်းမည်" ကို နှိပ်ပါ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisExtent: 180,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final origin = filtered[i];
                        return _buildOriginCard(context, origin);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginCard(BuildContext context, PlantOrigin origin) {
    final hasProducts = origin.productCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: origin.isActive
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Active Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (origin.isActive ? AppColors.primary : AppColors.textMuted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: 20,
                  color: origin.isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin.name,
                      style: TextStyle(
                        color: origin.isActive
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (origin.code != null && origin.code!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${origin.code}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (origin.isActive
                          ? const Color(0xFF10B981)
                          : AppColors.textMuted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  origin.isActive ? 'ဖွင့်လှစ်ထား' : 'ပိတ်ထား',
                  style: TextStyle(
                    color: origin.isActive
                        ? const Color(0xFF10B981)
                        : AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Usage count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  hasProducts
                      ? 'ပစ္စည်း ${origin.productCount} မျိုးတွင် အသုံးပြုထားသည်'
                      : 'ပစ္စည်းများတွင် အသုံးမပြုရသေးပါ',
                  style: TextStyle(
                    color: hasProducts
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Actions: Active Switch, Edit, Delete
          Row(
            children: [
              // Toggle Active
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: origin.isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(plantOriginProvider.notifier).updateOrigin(
                          origin.id,
                          isActive: val,
                        );
                  },
                ),
              ),
              Text(
                origin.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),

              const Spacer(),

              // Edit Action
              InkWell(
                onTap: () => _showAddEditOriginDialog(origin: origin),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Delete Action
              InkWell(
                onTap: () => _confirmDeleteOrigin(origin),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 14, color: AppColors.error),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit Origin Dialog ─────────────────────────────────

class _AddEditOriginDialog extends ConsumerStatefulWidget {
  const _AddEditOriginDialog({this.originToEdit});
  final PlantOrigin? originToEdit;

  @override
  ConsumerState<_AddEditOriginDialog> createState() =>
      _AddEditOriginDialogState();
}

class _AddEditOriginDialogState extends ConsumerState<_AddEditOriginDialog> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  bool _isSaving = false;

  bool get isEditing => widget.originToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final o = widget.originToEdit!;
      _nameCtrl.text = o.name;
      _codeCtrl.text = o.code ?? '';
      _sortCtrl.text = o.sortOrder.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.showError('မူရင်းဒေသ အမည် ထည့်သွင်းပေးပါ');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sortOrder = int.tryParse(_sortCtrl.text.trim()) ?? 0;
      final code = _codeCtrl.text.trim().isNotEmpty
          ? _codeCtrl.text.trim()
          : null;

      if (isEditing) {
        final ok = await ref.read(plantOriginProvider.notifier).updateOrigin(
              widget.originToEdit!.id,
              name: name,
              code: code,
              sortOrder: sortOrder,
            );
        if (mounted) {
          if (ok) {
            AppToast.showSuccess('မူရင်းဒေသ ပြင်ဆင်ပြီးပါပြီ');
            Navigator.of(context).pop();
          } else {
            AppToast.showError('ပြင်ဆင်မှု မအောင်မြင်ပါ');
          }
        }
      } else {
        final created = await ref.read(plantOriginProvider.notifier).addOrigin(
              name: name,
              code: code,
              sortOrder: sortOrder,
            );
        if (mounted) {
          if (created != null) {
            AppToast.showSuccess('မူရင်းဒေသ အသစ် ထည့်သွင်းပြီးပါပြီ');
            Navigator.of(context).pop();
          } else {
            AppToast.showError('ထည့်သွင်းမှု မအောင်မြင်ပါ');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'မူရင်းဒေသ ပြင်ဆင်ခြင်း (Edit Origin)'
                        : 'မူရင်းဒေသ အသစ်ထည့်သွင်းခြင်း (Add Origin)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Origin Name Field
            Text(
              'မူရင်းဒေသ အမည် (Origin Name) *',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'ဥပမာ - ဗီယက်နမ် Import၊ တောင်ကြီး၊ ပြင်ဦးလွင်',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Code Field (Optional)
            Text(
              'ကုဒ် / Identifier Code (Optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _codeCtrl,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'ဥပမာ - vietnam_import, local (ချန်ထားနိုင်သည်)',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'မလုပ်တော့ပါ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'သိမ်းဆည်းမည်' : 'ထည့်သွင်းမည်'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
