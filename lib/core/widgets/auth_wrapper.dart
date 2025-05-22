import 'package:e_commerce_app/core/widgets/background_decorations.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundDecorationsState(),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
