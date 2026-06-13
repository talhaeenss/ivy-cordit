import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Neobrutalism stilinde kart widget'ı
class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const BrutalCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BrutalStyle.cardDecorationWithColor(
          backgroundColor ?? AppColors.white,
        ),
        child: child,
      ),
    );
  }
}
