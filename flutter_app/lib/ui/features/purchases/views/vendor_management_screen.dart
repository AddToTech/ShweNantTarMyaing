// ============================================================
// VendorManagementScreen  — ကုန်သည်များ စီမံခန့်ခွဲမှု
// Full CRUD: list, add, edit, toggle active
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../view_models/vendor_notifier.dart';
import '../view_models/purchase_notifier.dart';
import '../../../shared/widgets/loading_view.dart';

final _mmk = NumberFormat('#,##0', 'en_US');

// ── Screen ────────────────────────────────────────────────────
class VendorManagementScreen extends ConsumerStatefulWidget {
  const VendorManagementScreen({
    super.key,
    this.isEmbedded = false,
  });

  final bool isEmbedded;

  @override
  ConsumerState<VendorManagementScreen> createState() =>
      _VendorManagementScreenState();
}

class _VendorManagementScreenState
    extends ConsumerState<VendorManagementScreen> {
  String _search = '';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorProvider);
    final isVendorLoading = ref.watch(vendorLoadingProvider);
    final filtered = vendors.where((v) {
      if (!_showInactive && !v.isActive) return false;
      if (_search.isNotEmpty &&
          !v.name.toLowerCase().contains(_search.toLowerCase()) &&
          !(v.phone?.contains(_search) ?? false)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: AppColors.surface,
          child: Row(
            children: [
              if (!widget.isEmbedded) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.1),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ကုန်သည်များ — Vendors / Suppliers',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ပစ္စည်းထောက်ပံ့သူများ စီမံခန့်ခွဲမှု',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'စုစုပေါင်း ကုန်သည် ${filtered.length} ဦး',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
              // Show inactive toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ရပ်ဆိုင်းထားသူများ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Switch(
                    value: _showInactive,
                    onChanged: (v) => setState(() => _showInactive = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Search
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'အမည် / ဖုန်းနံပါတ် ရှာ...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              // Add button
              FilledButton.icon(
                onPressed: () => _showVendorDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('ကုန်သည်သစ် ထည့်မည်'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // ── Table header ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: AppColors.surfaceVariant,
          child: const Row(
            children: [
              SizedBox(width: 44),
              SizedBox(
                  width: 220,
                  child: Text('အမည်',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 160,
                  child: Text('ဖုန်းနံပါတ်',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('လိပ်စာ',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 130,
                  child: Text('ကြွေးကျန်',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 80,
                  child: Text('မှတ်တမ်း',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 80,
                  child: Text('အတည်ပြု',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              SizedBox(width: 100),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Vendor list ──────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.wait([
                ref.read(vendorProvider.notifier).loadVendors(),
                ref.read(purchaseProvider.notifier).loadPurchases(),
              ]);
            },
            child: isVendorLoading && filtered.isEmpty
                ? const Center(
                    child: AppLoadingView(
                      message: 'ကုန်သည်/ပစ္စည်းသွင်းသူ စာရင်းများ ရယူနေပါသည်...',
                      subMessage: 'Loading vendors...',
                      icon: Icons.handshake_outlined,
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
                              Icon(Icons.people_outline_rounded,
                                  size: 60,
                                  color: AppColors.textSecondary.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('ကုန်သည် မရှိသေးပါ',
                                  style:
                                      TextStyle(color: AppColors.textSecondary)),
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
                    itemBuilder: (ctx, i) => _VendorRow(
                      vendor: filtered[i],
                      onEdit: () => _showVendorDialog(ctx, vendor: filtered[i]),
                      onToggleActive: () => ref
                          .read(vendorProvider.notifier)
                          .toggleActive(filtered[i].id),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showVendorDialog(BuildContext context, {Vendor? vendor}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VendorDialog(vendor: vendor),
    );
  }
}

// ── Vendor table row ──────────────────────────────────────────
class _VendorRow extends ConsumerWidget {
  const _VendorRow({
    required this.vendor,
    required this.onEdit,
    required this.onToggleActive,
  });
  final Vendor vendor;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payables = ref.watch(vendorPayablesProvider(vendor.id));
    final purchases = ref.watch(purchaseProvider).purchases;
    final invoiceCount =
        purchases.where((p) => p.vendorId == vendor.id).length;

    return Opacity(
      opacity: vendor.isActive ? 1.0 : 0.5,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🏪', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),

            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (vendor.notes != null)
                    Text(vendor.notes!,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            SizedBox(
              width: 160,
              child: Text(vendor.phone ?? '—',
                  style: const TextStyle(fontSize: 12)),
            ),

            Expanded(
              child: Text(
                vendor.address ?? '—',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Payables
            SizedBox(
              width: 130,
              child: payables > 0
                  ? Text(
                      '${_mmk.format(payables)} Ks',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning),
                    )
                  : Text('—',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
            ),

            // Invoice count
            SizedBox(
              width: 80,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$invoiceCount',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ),
            ),

            // Active status
            SizedBox(
              width: 80,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: vendor.isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendor.isActive ? 'Active' : 'ရပ်ဆိုင်း',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: vendor.isActive
                            ? AppColors.success
                            : AppColors.error),
                  ),
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'ပြင်ဆင်မည်',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: vendor.isActive ? 'ရပ်ဆိုင်းမည်' : 'ပြန်ဖွင့်မည်',
                    icon: Icon(
                      vendor.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 22,
                    ),
                    color: vendor.isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    onPressed: onToggleActive,
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

// ══════════════════════════════════════════════════════════════
// Add / Edit Vendor Dialog
// ══════════════════════════════════════════════════════════════
class _VendorDialog extends ConsumerStatefulWidget {
  const _VendorDialog({this.vendor});
  final Vendor? vendor;

  @override
  ConsumerState<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends ConsumerState<_VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  late bool _isActive;

  bool get _isEdit => widget.vendor != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vendor?.name);
    _phoneCtrl = TextEditingController(text: widget.vendor?.phone);
    _addressCtrl = TextEditingController(text: widget.vendor?.address);
    _notesCtrl = TextEditingController(text: widget.vendor?.notes);
    _isActive = widget.vendor?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(vendorProvider.notifier);

    if (_isEdit) {
      final ok = await notifier.updateVendor(widget.vendor!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        clearPhone: _phoneCtrl.text.trim().isEmpty,
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        clearAddress: _addressCtrl.text.trim().isEmpty,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        clearNotes: _notesCtrl.text.trim().isEmpty,
        isActive: _isActive,
      ));
      if (!ok || !mounted) return;
    } else {
      final created = await notifier.addVendor(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
      if (created == null || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(
          children: [
            Icon(
              _isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              _isEdit ? 'ကုန်သည် ပြင်ဆင်မည်' : 'ကုန်သည်သစ် ထည့်သွင်းမည်',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              _FormField(
                label: 'ကုန်သည်အမည် *',
                ctrl: _nameCtrl,
                icon: Icons.store_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'အမည် ထည့်သွင်းပါ' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'ဖုန်းနံပါတ်',
                ctrl: _phoneCtrl,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'လိပ်စာ',
                ctrl: _addressCtrl,
                icon: Icons.location_on_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'မှတ်ချက်',
                ctrl: _notesCtrl,
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.toggle_on_rounded,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Text('အသုံးပြုနေဆဲ (Active)',
                        style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ဖျက်သိမ်းမည်'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: Text(_isEdit ? 'ပြင်ဆင်မည်' : 'ထည့်သွင်းမည်'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ── Reusable form field ───────────────────────────────────────
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
