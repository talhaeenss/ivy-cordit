import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Neobrutalism stilinde input widget'ı
/// Focus animasyonu ile
class BrutalInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final bool enabled;

  const BrutalInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  State<BrutalInput> createState() => _BrutalInputState();
}

class _BrutalInputState extends State<BrutalInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.white : AppColors.bgMain,
            border: Border.all(
              color: _isFocused ? AppColors.primary : AppColors.black,
              width: BrutalStyle.borderWidth,
            ),
            boxShadow: _isFocused
                ? const [
                    BoxShadow(
                      color: AppColors.primary,
                      offset: Offset(
                        BrutalStyle.shadowOffset,
                        BrutalStyle.shadowOffset,
                      ),
                      blurRadius: 0,
                    ),
                  ]
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
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.grey.withAlpha(178),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
