import 'package:e_commerce_app/features/authentication/screens/email_verification_screen.dart';
import 'package:e_commerce_app/features/authentication/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/core/widgets/background_decorations.dart';

import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/signup_screen.dart';

class AuthWrapper extends StatefulWidget {
  final String? initialScreen; // Add this parameter
  const AuthWrapper({super.key,this.initialScreen});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late String _currentScreen;

  @override
  void initState() {
    super.initState();
    // Set initial screen based on parameter, default to splash
    _currentScreen = widget.initialScreen ?? 'splash';
  }
  String? _email;
  void _changeScreen(String screen, {String? email}) {
    setState(() {
      _currentScreen = screen;
      if (email != null) {
        _email = email;
      }
    });
  }

  Widget _getScreen() {
    switch (_currentScreen) {
      case 'splash':
        return SplashScreen(onSwitch:_changeScreen);
      case 'signup':
        return SignupScreen(onSwitch: _changeScreen);
      case 'forgotPassword':
        return ForgotPasswordScreen(onSwitch: _changeScreen);
      case 'verify':
        return EmailVerificationScreen(onSwitch: _changeScreen, email: _email ?? '',);
      case 'login':
        return LoginScreen(onSwitch: _changeScreen);
      default:
        return LoginScreen(onSwitch: _changeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundDecorationsState(),
        Positioned.fill(
          child: _getScreen(),
        ),
      ],
    );
  }
}
