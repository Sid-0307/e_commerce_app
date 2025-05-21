import 'package:e_commerce_app/features/authentication/widgets/auth_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/background_decorations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../admin/screens/admin_home_screen.dart';
import '../../buyer/screens/buyer_home_screen.dart';
import '../../vendor/screens/vendor_home_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation
    _controller.forward();

    // Check authentication status after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      UserModel? user = await _authService.getCurrentUser();

      if (user != null && mounted) {
        // Set user in provider
        await Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);

        // Navigate based on user type
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (user.userType == 'Seller') {
                  return const VendorHomeScreen();
                } else if (user.userType == 'Buyer') {
                  return const BuyerHomeScreen();
                } else if (user.userType == 'Admin') {
                  return const AdminHomeScreen();
                } else {
                  // Fallback
                  return const LoginScreen();
                }
              },
            ),
          );
        }
      } else if (mounted) {
        // No user found, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Error occurred, go to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundDecorations(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AuthCard(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo or app name
                              Text(
                                'MILLIG',
                                style: AppTextStyles.appName.copyWith(
                                  fontSize: 42,
                                  foreground: Paint()..color = AppColors.primary,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: AppColors.tertiary.withOpacity(0.6),
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Loading indicator
                              const CircularProgressIndicator(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}