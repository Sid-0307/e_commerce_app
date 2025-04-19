import 'package:e_commerce_app/core/constants/colors.dart';
import 'package:flutter/material.dart';

class BackgroundDecorations extends StatelessWidget {
  final Widget child;

  const BackgroundDecorations({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background decorations
        Positioned(
          left: -100,
          top: -50,
          right: -100,
          child: _buildBlob1(),
        ),
        // Positioned(
        //   bottom: -100,
        //   left: -100,
        //   child: _buildBlob2(),
        // ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: -20,
          child: _buildLine(),
        ),
        // Content
        child,
      ],
    );
  }

  Widget _buildBlob1() {
    return Opacity(
      opacity: 0.75,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.secondary, // Dark blue
          borderRadius: BorderRadius.circular(200),
        ),
      ),
    );
  }

  Widget _buildBlob2() {
    return Opacity(
      opacity: 0.15,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Color(0xFF1E3B70), // Another shade of dark blue
          borderRadius: BorderRadius.circular(150),
        ),
      ),
    );
  }

  Widget _buildLine() {
    return Opacity(
      opacity: 0.07,
      child: Container(
        width: 150,
        height: 3,
        decoration: BoxDecoration(
          color: Color(0xFF0A2472), // Dark blue
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}