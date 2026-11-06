import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../shared/widgets/product_avatar.dart';
import '../view_models/cart_notifier.dart';

// ============================================================
// ProductGridItem
// ============================================================

class ProductGridItem extends ConsumerStatefulWidget {
  const ProductGridItem({super.key, required this.product});
  final MockProduct product;

  @override
  ConsumerState<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends ConsumerState<ProductGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _scaleCtrl.reverse();
    ref.read(cartProvider.notifier).addItem(widget.product);
    await _scaleCtrl.forward();
  }

  Color get _bgColor => switch (widget.product.category) {
        ProductCategory.plants    => AppColors.catPlants,
        ProductCategory.pots      => AppColors.catPots,
        ProductCategory.chemicals => AppColors.catChemicals,
        ProductCategory.tools     => AppColors.catTools,
        _                         => AppColors.catOthers,
      };

  Color get _originColor {
    if (widget.product.originType != null) {
      return switch (widget.product.originType!) {
        OriginType.thaiImport  => AppColors.originThai,
        OriginType.chinaImport => AppColors.originChina,
        OriginType.local       => AppColors.originLocal,
      };
    }
    if (widget.product.originName != null && widget.product.originName!.isNotEmpty) {
      final lower = widget.product.originName!.toLowerCase();
      if (lower.contains('thai') || lower.contains('ယိုးဒယား')) return AppColors.originThai;
      if (lower.contains('china') || lower.contains('တရုတ်')) return AppColors.originChina;
      if (lower.contains('local') || lower.contains('ပြည်တွင်း')) return AppColors.originLocal;
      return const Color(0xFF0EA5E9);
    }
    return Colors.transparent;
  }

  String get _originLabel {
    if (widget.product.originType != null) {
      return switch (widget.product.originType!) {
        OriginType.thaiImport  => 'ယိုးဒယား',
        OriginType.chinaImport => 'တရုတ်',
        OriginType.local       => 'ပြည်တွင်း',
      };
    }
    if (widget.product.originName != null && widget.product.originName!.isNotEmpty) {
      return widget.product.originName!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider).items;
    final qtyInCart = cartItems
        .where((i) => i.product.id == widget.product.id)
        .fold(0, (s, i) => s + i.quantity);
    final fmt = NumberFormat('#,###');

    final isOutOfStock = widget.product.isOutOfStock;

    return AnimatedBuilder(
      animation: _scaleCtrl,
      builder: (_, child) => Transform.scale(scale: _scaleCtrl.value, child: child),
      child: GestureDetector(
        onTap: isOutOfStock ? null : _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: qtyInCart > 0
                  ? AppColors.primary
                  : AppColors.border,
              width: qtyInCart > 0 ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image / Emoji area ────────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background & product image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _bgColor.withValues(alpha: 0.30),
                              _bgColor.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                        child: Center(
                          child: ProductAvatar(
                            imageEmoji: widget.product.imageEmoji,
                            customImagePath: widget.product.customImagePath,
                            width: double.infinity,
                            height: double.infinity,
                            fontSize: 34,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),

                    // Origin badge (top-left)
                    if (widget.product.originType != null)
                      Positioned(
                        top: 5, left: 5,
                        child: _Badge(
                          label: _originLabel,
                          color: _originColor,
                        ),
                      ),

                    // Stock badge (top-right)
                    Positioned(
                      top: 5, right: 5,
                      child: _Badge(
                        label: '${widget.product.stock}',
                        color: widget.product.isLowStock
                            ? AppColors.error
                            : Colors.black.withValues(alpha: 0.50),
                        textColor: Colors.white,
                        hasBorder: !widget.product.isLowStock,
                      ),
                    ),

                    // In-cart quantity bubble (bottom-right)
                    if (qtyInCart > 0)
                      Positioned(
                        bottom: 5, right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_cart_rounded, size: 10, color: AppColors.textOnPrimary),
                              const SizedBox(width: 3),
                              Text(
                                '$qtyInCart',
                                style: const TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Out-of-stock overlay
                    if (isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11)),
                        ),
                        child: const Center(
                          child: Text(
                            'ပစ္စည်းပြတ်\n(OUT OF STOCK)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Product info ──────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOutOfStock
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${fmt.format(widget.product.salePrice)} Ks',
                            style: TextStyle(
                              color: isOutOfStock
                                  ? AppColors.textMuted
                                  : AppColors.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.product.sizeLabel != null &&
                              widget.product.sizeLabel!.isNotEmpty)
                            Flexible(
                              child: Text(
                                widget.product.sizeLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge helper ──────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.hasBorder = false,
  });
  final String label;
  final Color color;
  final Color textColor;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: hasBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
