import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Neobrutalism stilinde buton widget'ı
/// Press animasyonu ile sert gölge efekti
class BrutalButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const BrutalButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.isLoading = false,
    this.icon,
    this.child,
    this.padding,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.primary;
    final txtColor = widget.textColor ?? AppColors.white;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _setPressed(true) : null,
      onTapUp: widget.onPressed != null ? (_) => _setPressed(false) : null,
      onTapCancel: widget.onPressed != null ? () => _setPressed(false) : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          _isPressed ? BrutalStyle.shadowOffset : 0,
          _isPressed ? BrutalStyle.shadowOffset : 0,
          0,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.onPressed == null ? AppColors.grey : bgColor,
          border: Border.all(
            color: AppColors.black,
            width: BrutalStyle.borderWidth,
          ),
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: Offset(
                      BrutalStyle.shadowOffset,
                      BrutalStyle.shadowOffset,
                    ),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                  ),
                )
              : widget.child ?? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: txtColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    if (widget.text.isNotEmpty)
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: txtColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    setState(() => _isPressed = value);
  }
}
