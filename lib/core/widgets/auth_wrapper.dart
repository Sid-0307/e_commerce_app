import 'package:e_commerce_app/core/widgets/background_decorations.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Container(
        //   decoration: const BoxDecoration(
        //     color: AppColors.lightTertiary,
        //   ),
        // ),
        const BackgroundDecorationsState(),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
