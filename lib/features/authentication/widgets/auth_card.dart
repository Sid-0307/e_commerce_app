import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final double width;

  const AuthCard({
    super.key,
    required this.child,
    this.width = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: width,
      ),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}