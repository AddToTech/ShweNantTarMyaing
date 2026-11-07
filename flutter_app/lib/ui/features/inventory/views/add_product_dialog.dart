import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../../settings/view_models/category_notifier.dart';
import '../../settings/view_models/plant_origin_notifier.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../view_models/inventory_notifier.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({
    super.key,
    this.productToEdit,
    this.initialBranchStockA,
    this.initialBranchStockB,
  });

  final MockProduct? productToEdit;
  final int? initialBranchStockA;
  final int? initialBranchStockB;

  bool get isEditing => productToEdit != null;

  static Future<void> show(
    BuildContext context, {
    MockProduct? productToEdit,
    int? initialBranchStockA,
    int? initialBranchStockB,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddProductDialog(
        productToEdit: productToEdit,
        initialBranchStockA: initialBranchStockA,
        initialBranchStockB: initialBranchStockB,
      ),
    );
  }

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController(text: '5');
  final _sizeLabelCtrl = TextEditingController();
  final Map<String, TextEditingController> _branchStockCtrls = {};

  ProductCategory _category = ProductCategory.plants;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedOriginId;
  String? _selectedOriginName;
  OriginType? _originType = OriginType.thaiImport;
  String _subcategory = 'အထွေထွေ';
  String? _selectedVendorId;
  String _selectedEmoji = '🪴';
  String? _customImagePath;
  bool _isSaving = false;

  static const Map<ProductCategory, List<String>> _categoryEmojis = {
    ProductCategory.plants: ['🪴', '🌿', '🌸', '🌺', '🌹', '🌻', '🥭', '🎍'],
    ProductCategory.pots: ['🏺', '🪴', '🧱', '🪨', '🥣', '🟫'],
    ProductCategory.chemicals: ['🧪', '💧', '🧴', '🌱', '⚡️'],
    ProductCategory.tools: ['✂️', '🪓', '🪣', '⛏️', '🧤', '🚿'],
    ProductCategory.others: ['🌍', '🪨', '📦', '🏷️', '🪵'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final p = widget.productToEdit!;
      _nameCtrl.text = p.name;
      _skuCtrl.text = p.sku;
      _barcodeCtrl.text = p.barcode ?? '';
      _salePriceCtrl.text = p.salePrice == p.salePrice.roundToDouble()
          ? p.salePrice.toInt().toString()
          : p.salePrice.toString();
      _costPriceCtrl.text = p.costPrice == p.costPrice.roundToDouble()
          ? p.costPrice.toInt().toString()
          : p.costPrice.toString();
      _minStockCtrl.text = p.minStock.toString();
      _sizeLabelCtrl.text = p.sizeLabel ?? '';
      _category = p.category;
      _selectedCategoryId = p.categoryId;
      _selectedCategoryName = p.categoryName;
      _originType = p.originType;
      _selectedOriginId = p.originId;
      _selectedOriginName = p.originName ?? p.originType?.burmeseLabel ?? 'ယိုးဒယား Import';
      _subcategory = p.subcategory.isNotEmpty ? p.subcategory : 'အထွေထွေ';
      _selectedVendorId = p.vendorId;
      _selectedEmoji = p.imageEmoji;
      _customImagePath = p.customImagePath;

      if (widget.initialBranchStockA != null) {
        _branchStockCtrls['branch_a'] = TextEditingController(text: widget.initialBranchStockA.toString());
      }
      if (widget.initialBranchStockB != null) {
        _branchStockCtrls['branch_b'] = TextEditingController(text: widget.initialBranchStockB.toString());
      }
    } else {
      _generateSkuAndBarcode();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _salePriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _sizeLabelCtrl.dispose();
    for (final c in _branchStockCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _generateSkuAndBarcode() {
    final prefix = switch (_category) {
      ProductCategory.plants => 'PLT',
      ProductCategory.pots => 'POT',
      ProductCategory.chemicals => 'CHM',
      ProductCategory.tools => 'TLS',
      ProductCategory.others => 'OTH',
      ProductCategory.all => 'PRD',
    };
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final randNum = (100 + Random().nextInt(900)).toString();
    _skuCtrl.text = '$prefix-$timestamp-$randNum';
    _barcodeCtrl.text = '';
  }

  List<String> _getSubcategories(ProductCategory category) {
    final dynamicSubs = ref
        .read(categoryNotifierProvider.notifier)
        .getSubcategoriesForCategory(category, categoryId: _selectedCategoryId);
    if (dynamicSubs.isNotEmpty) return dynamicSubs;
    return const ['အထွေထွေ'];
  }

  void _onCategoryItemSelected(CategoryItem item) {
    setState(() {
      _selectedCategoryId = item.id;
      _selectedCategoryName = item.name;
      _category = item.standardCategory ?? ProductCategory.others;
      final subs = item.subcategories.isNotEmpty
          ? item.subcategories
          : _getSubcategories(_category);
      _subcategory = subs.isNotEmpty ? subs.first : 'အထွေထွေ';
      final emojis = item.standardCategory != null
          ? (_categoryEmojis[item.standardCategory!] ?? [item.emoji])
          : [item.emoji, '📦', '🏷️', '🌿', '🪴'];
      _selectedEmoji = emojis.first;
      if (!widget.isEditing) {
        _generateSkuAndBarcode();
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _customImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ဓာတ်ပုံရွေးချယ်ရာတွင် အဆင်မပြေပါ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final salePrice = double.tryParse(_salePriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final costPrice = double.tryParse(_costPriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final minStock = int.tryParse(_minStockCtrl.text.trim()) ?? 5;

    final branchStocks = <String, int>{};
    for (final entry in _branchStockCtrls.entries) {
      final qty = int.tryParse(entry.value.text.trim()) ?? 0;
      branchStocks[entry.key] = qty;
    }
    final firstStock = branchStocks.values.firstOrNull ?? 0;

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        final updatedProduct = widget.productToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _category,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          subcategory: _subcategory,
          salePrice: salePrice,
          costPrice: costPrice,
          stock: firstStock,
          minStock: minStock,
          originType: _originType,
          originId: _selectedOriginId,
          originName: _selectedOriginName,
          sizeLabel: _sizeLabelCtrl.text.trim().isNotEmpty ? _sizeLabelCtrl.text.trim() : null,
          vendorId: _selectedVendorId,
          vendorName: ref.read(vendorProvider).where((v) => v.id == _selectedVendorId).firstOrNull?.name,
          imageEmoji: _selectedEmoji,
          customImagePath: _customImagePath,
          clearCustomImage: _customImagePath == null,
          sku: _skuCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
        );

        final ok = await ref.read(catalogProvider.notifier).updateProduct(
              updatedProduct,
              branchStocks: branchStocks,
            );

        if (!ok || !mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                ProductAvatar(
                  imageEmoji: _selectedEmoji,
                  customImagePath: _customImagePath,
                  size: 24,
                  fontSize: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('ကုန်ပစ္စည်း "${updatedProduct.name}" အချက်အလက်များကို ပြင်ဆင်ပြီးပါပြီ။'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final newId = 'prod_${DateTime.now().millisecondsSinceEpoch}';

      final newProduct = MockProduct(
        id: newId,
        name: _nameCtrl.text.trim(),
        category: _category,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        subcategory: _subcategory,
        salePrice: salePrice,
        costPrice: costPrice,
        stock: firstStock,
        minStock: minStock,
        originType: _originType,
        originId: _selectedOriginId,
        originName: _selectedOriginName,
        sizeLabel: _sizeLabelCtrl.text.trim().isNotEmpty ? _sizeLabelCtrl.text.trim() : null,
        vendorId: _selectedVendorId,
        vendorName: ref.read(vendorProvider).where((v) => v.id == _selectedVendorId).firstOrNull?.name,
        imageEmoji: _selectedEmoji,
        customImagePath: _customImagePath,
        sku: _skuCtrl.text.trim().isNotEmpty
            ? _skuCtrl.text.trim()
            : 'PRD-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
        barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      );

      // Save to catalog & initialize branch stocks
      final ok = await ref.read(catalogProvider.notifier).addProduct(
        newProduct,
        branchStocks: branchStocks,
      );

      if (!ok || !mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              ProductAvatar(
                imageEmoji: _selectedEmoji,
                customImagePath: _customImagePath,
                size: 24,
                fontSize: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Successfully added "${newProduct.name}" to inventory!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showQuickAddOriginDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.public_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'မူရင်းဒေသ အသစ်ထည့်မည်',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'မူရင်းဒေသ အမည် (ဥပမာ - ဗီယက်နမ် Import၊ တောင်ကြီး)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'မူရင်းဒေသ ရိုက်ထည့်ပါ...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('မလုပ်တော့ပါ',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = textCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final created = await ref
                  .read(plantOriginProvider.notifier)
                  .addOrigin(name: name);
              if (created != null && mounted) {
                setState(() {
                  _selectedOriginName = created.name;
                  _selectedOriginId = created.id;
                  final lower = created.name.toLowerCase();
                  if (lower.contains('thai') || lower.contains('ယိုးဒယား')) {
                    _originType = OriginType.thaiImport;
                  } else if (lower.contains('china') || lower.contains('တရုတ်')) {
                    _originType = OriginType.chinaImport;
                  } else if (lower.contains('local') || lower.contains('ပြည်တွင်း')) {
                    _originType = OriginType.local;
                  } else {
                    _originType = null;
                  }
                });
              }
            },
            child: const Text('ထည့်သွင်းမည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final sale = double.tryParse(_salePriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final cost = double.tryParse(_costPriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final marginVal = sale - cost;
    final marginPct = sale > 0 ? ((marginVal / sale) * 100) : 0.0;

    final allBranches = ref.watch(branchListNotifierProvider);
    final activeBranches = allBranches.where((b) => b.isActive).toList();

    final List<({String id, String name})> branchItems = [];
    if (activeBranches.isNotEmpty) {
      for (final b in activeBranches) {
        branchItems.add((id: b.id, name: b.name));
      }
    } else {
      final addedIds = <String>{};
      for (final entry in kBranches.entries) {
        final bId = kBranchKeyToUuid[entry.key] ?? entry.key;
        if (!addedIds.contains(bId)) {
          addedIds.add(bId);
          branchItems.add((id: bId, name: entry.value.split('(').first.trim()));
        }
      }
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 740),
        child: Column(
          children: [
            // ── Dialog Header ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing
                              ? 'Edit Product (ကုန်ပစ္စည်း အချက်အလက် ပြင်ဆင်ခြင်း)'
                              : 'Add New Product',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.isEditing
                              ? 'အမည်၊ အမျိုးအစား၊ ရောင်းဈေး၊ အရင်းဈေးနှင့် လက်ကျန်များ ပြင်ဆင်မည်'
                              : 'ပစ္စည်းအသစ် ထည့်သွင်းခြင်း (POS & Inventory သို့ တိုက်ရိုက်ထည့်မည်)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (_isSaving)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
              ),

            // ── Scrollable Form Body ────────────────────────────
            Expanded(
              child: IgnorePointer(
                ignoring: _isSaving,
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Selector Chips
                      Text(
                        'CATEGORY (အမျိုးအစား)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final activeCategories = ref.watch(categoryNotifierProvider);
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: activeCategories.map((catItem) {
                              final selected = _selectedCategoryId != null
                                  ? _selectedCategoryId == catItem.id
                                  : (catItem.standardCategory != null &&
                                      catItem.standardCategory == _category);
                              final label = catItem.englishName.isNotEmpty &&
                                      catItem.englishName.toLowerCase() !=
                                          catItem.name.toLowerCase()
                                  ? '${catItem.emoji} ${catItem.englishName} (${catItem.name})'
                                  : '${catItem.emoji} ${catItem.name}';
                              return ChoiceChip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
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
                                backgroundColor: AppColors.surfaceVariant,
                                onSelected: (_) =>
                                    _onCategoryItemSelected(catItem),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Product Name & Emoji/Custom Image Selection Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Avatar (Emoji or Custom Image)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ICON / IMAGE',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Tooltip(
                                    message: _customImagePath != null
                                        ? 'Tap to change image'
                                        : 'Tap to pick image from gallery',
                                    child: InkWell(
                                      onTap: _pickImageFromGallery,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _customImagePath != null
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: _customImagePath != null ? 1.5 : 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: ProductAvatar(
                                            imageEmoji: _selectedEmoji,
                                            customImagePath: _customImagePath,
                                            size: 56,
                                            fontSize: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_customImagePath != null)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Tooltip(
                                        message: 'Remove photo (use icon)',
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _customImagePath = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Product Name Field
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRODUCT NAME (ပစ္စည်းအမည်) *',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Monstera Deliciosa (မွန်းစတာရာ)',
                                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter a product name';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Quick Emoji Picker & Custom Image Picker Row
                      Row(
                        children: [
                          Text(
                            'Quick Icon:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: (_categoryEmojis[_category] ?? []).map((emoji) {
                                  final isSel = _customImagePath == null && _selectedEmoji == emoji;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = emoji;
                                        _customImagePath = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSel ? AppColors.primary : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Gallery Pick Button
                          OutlinedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: Icon(
                              _customImagePath != null ? Icons.photo_library_rounded : Icons.add_photo_alternate_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _customImagePath != null ? 'Change Photo' : 'Gallery Photo (ဓာတ်ပုံ)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _customImagePath != null
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _customImagePath != null
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Dynamic Fields (Origin & Subcategory)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Origin Selector (All Categories)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'PLANT ORIGIN (မူရင်းဒေသ)',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _showQuickAddOriginDialog(context),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_circle_outline_rounded, size: 13, color: AppColors.primary),
                                            SizedBox(width: 3),
                                            Text(
                                              'အသစ်ထည့်',
                                              style: TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final origins = ref.watch(activePlantOriginsProvider);
                                    final currentName = origins.any((o) => o.name == _selectedOriginName)
                                        ? _selectedOriginName
                                        : (origins.isNotEmpty ? origins.first.name : null);

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: currentName,
                                          isExpanded: true,
                                          dropdownColor: AppColors.surfaceVariant,
                                          items: [
                                            ...origins.map((o) {
                                              return DropdownMenuItem<String?>(
                                                value: o.name,
                                                child: Text(
                                                  o.name,
                                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedOriginName = val;
                                                final matched = origins.where((o) => o.name == val).firstOrNull;
                                                _selectedOriginId = matched?.id;
                                                final lower = val.toLowerCase();
                                                if (lower.contains('thai') || lower.contains('ယိုးဒယား')) {
                                                  _originType = OriginType.thaiImport;
                                                } else if (lower.contains('china') || lower.contains('တရုတ်')) {
                                                  _originType = OriginType.chinaImport;
                                                } else if (lower.contains('local') || lower.contains('ပြည်တွင်း')) {
                                                  _originType = OriginType.local;
                                                } else {
                                                  _originType = null;
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Subcategory Selector
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SUBCATEGORY (အုပ်စုခွဲ)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final currentSubs = _getSubcategories(_category);
                                    final activeSub = currentSubs.contains(_subcategory)
                                        ? _subcategory
                                        : (currentSubs.isNotEmpty ? currentSubs.first : null);

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: activeSub,
                                          isExpanded: true,
                                          dropdownColor: AppColors.surfaceVariant,
                                          items: currentSubs.map((s) {
                                            return DropdownMenuItem(value: s, child: Text(s));
                                          }).toList(),
                                          onChanged: (v) {
                                            if (v != null) setState(() => _subcategory = v);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Vendor Selector
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VENDOR (ကုန်သည် / ဆိုင်)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final vendors = ref.watch(activeVendorsProvider);
                                    final currentVendorId = vendors.any((v) => v.id == _selectedVendorId)
                                        ? _selectedVendorId
                                        : null;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: currentVendorId,
                                          isExpanded: true,
                                          dropdownColor: AppColors.surfaceVariant,
                                          hint: Text(
                                            'မရွေးချယ်ပါ (None)',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                          ),
                                          items: [
                                            DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text(
                                                'မရွေးချယ်ပါ (None)',
                                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                              ),
                                            ),
                                            ...vendors.map((v) {
                                              return DropdownMenuItem<String?>(
                                                value: v.id,
                                                child: Text(
                                                  v.name,
                                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (v) {
                                            setState(() => _selectedVendorId = v);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ── Pricing & Margins ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PRICING & PROFIT MARGIN (ဈေးနှုန်းနှင့် အမြတ်ငွေ)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (sale > 0 && cost > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: marginPct >= 30
                                          ? AppColors.success.withValues(alpha: 0.2)
                                          : AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Margin: ${marginPct.toStringAsFixed(1)}% (+${currencyFmt.format(marginVal)} Ks)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: marginPct >= 30 ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Sale Price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sale Price (ရောင်းဈေး MMK) *',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _salePriceCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 25,000',
                                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                          suffixText: 'Ks',
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: AppColors.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Enter sale price';
                                          if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid price';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Cost Price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cost Price (အရင်းဈေး MMK) *',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _costPriceCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 15,000',
                                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                          suffixText: 'Ks',
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: AppColors.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Enter cost price';
                                          if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid cost';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Initial Stock Setup ───────────────────────────
                      Text(
                        widget.isEditing
                            ? 'STOCK QUANTITY (ဆိုင်ခွဲအလိုက် လက်ကျန်အရေအတွက် ပြင်ဆင်ခြင်း)'
                            : 'INITIAL STOCK ALLOCATION (ဆိုင်ခွဲအလိုက် စတင်လက်ကျန်)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...branchItems.map((branch) {
                            final ctrl = _branchStockCtrls.putIfAbsent(
                              branch.id,
                              () {
                                final invStock = widget.isEditing
                                    ? ref.read(inventoryProvider).getStock(branch.id, widget.productToEdit?.id ?? '')
                                    : null;
                                final defaultStock = invStock ?? 0;
                                return TextEditingController(text: defaultStock.toString());
                              },
                            );

                            final displayName = branch.name.length > 22
                                ? '${branch.name.substring(0, 20)}...'
                                : branch.name;

                            return SizedBox(
                              width: 220,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$displayName Stock:',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.store_rounded, size: 16, color: AppColors.primary),
                                      filled: true,
                                      fillColor: AppColors.surfaceVariant,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Min Alert Stock:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _minStockCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

            // ── Dialog Actions Footer ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel (ပယ်ဖျက်မည်)', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProduct,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSaving
                          ? 'သိမ်းဆည်းနေပါသည်...'
                          : (widget.isEditing
                              ? 'Update Product (အချက်အလက် ပြင်ဆင်မည်)'
                              : 'Save & Add to Catalog (သိမ်းဆည်းမည်)'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
