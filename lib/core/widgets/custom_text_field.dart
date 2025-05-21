import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Icon? prefixIcon; // Added optional prefix icon
  final Color? prefixIconColor; // Added optional prefix icon color

  const CustomTextField({
    super.key,
    required this.labelText,
    this.obscureText = false,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon, // Adding to constructor
    this.prefixIconColor, // Adding to constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: AppColors.black.withOpacity(0.6),
          // fontFamily: 'Montserrat',
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: AppColors.tertiary.withOpacity(0.15),
        contentPadding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? 8 : 16,
            vertical: 16
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: IconTheme(
            data: IconThemeData(
              color: prefixIconColor ?? AppColors.primary.withOpacity(0.7),
              size: 20,
            ),
            child: prefixIcon!,
          ),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // Dark border
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
          // fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
        ),
      ),
      style: const TextStyle(
        // fontFamily: 'Montserrat',
      ),
    );
  }
}