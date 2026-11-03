import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable widget for rendering a product's visual representation.
/// Displays a custom device/gallery image when available,
/// with automatic fallback to the product's emoji icon.
class ProductAvatar extends StatelessWidget {
  const ProductAvatar({
    super.key,
    required this.imageEmoji,
    this.customImagePath,
    this.size,
    this.width,
    this.height,
    this.fontSize = 24,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  final String imageEmoji;
  final String? customImagePath;
  final double? size;
  final double? width;
  final double? height;
  final double fontSize;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size ?? 36;
    final h = height ?? size ?? 36;

    if (customImagePath != null && customImagePath!.trim().isNotEmpty) {
      final path = customImagePath!.trim();
      Widget imageWidget;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        imageWidget = Image.network(
          path,
          width: w,
          height: h,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildEmojiFallback(w, h),
        );
      } else if (path.startsWith('assets/')) {
        imageWidget = Image.asset(
          path,
          width: w,
          height: h,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildEmojiFallback(w, h),
        );
      } else {
        // Local device file path
        if (kIsWeb) {
          imageWidget = Image.network(
            path,
            width: w,
            height: h,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildEmojiFallback(w, h),
          );
        } else {
          final file = File(path);
          imageWidget = Image.file(
            file,
            width: w,
            height: h,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildEmojiFallback(w, h),
          );
        }
      }

      if (borderRadius > 0) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: w,
            height: h,
            child: imageWidget,
          ),
        );
      }
      return SizedBox(
        width: w,
        height: h,
        child: imageWidget,
      );
    }

    return _buildEmojiFallback(w, h);
  }

  Widget _buildEmojiFallback(double w, double h) {
    return SizedBox(
      width: w,
      height: h,
      child: Center(
        child: Text(
          imageEmoji,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
