import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Icon? prefixIcon;
  final Color? prefixIconColor;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.obscureText = false,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _showSuffix = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
    _showSuffix = widget.controller.text.isNotEmpty;
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_showSuffix != hasText) {
      setState(() {
        _showSuffix = hasText;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: AppColors.black.withOpacity(0.6),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: AppColors.tertiary.withOpacity(0.15),
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.prefixIcon != null ? 8 : 16,
          vertical: 16,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: IconTheme(
            data: IconThemeData(
              color: widget.prefixIconColor ?? AppColors.primary.withOpacity(0.7),
              size: 20,
            ),
            child: widget.prefixIcon!,
          ),
        )
            : null,
        suffixIcon: (_showSuffix && widget.suffixIcon != null)
            ? Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: IconTheme(
            data: IconThemeData(
              color: AppColors.primary.withOpacity(0.7),
              size: 20,
            ),
            child: widget.suffixIcon!,
          ),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
