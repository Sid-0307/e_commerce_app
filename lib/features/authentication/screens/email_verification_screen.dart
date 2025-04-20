import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/background_decorations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/logo_widget.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  late Timer _timer;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 60; // Cooldown period in seconds

  @override
  void initState() {
    super.initState();
    // Verify email status on initialization
    _checkEmailVerified();
    _resendVerificationEmail();
    // Set up timer to check verification status periodically
    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkEmailVerified(),
    );

    // Set up timer for resend cooldown
    _startResendCooldownTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    try {
      final isVerified = await _authService.isEmailVerified();

      if (isVerified) {
        _timer.cancel();

        if (mounted) {
          setState(() {
            _isEmailVerified = true;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );

          // Give user time to see the success message before redirecting
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          });
        }
      }
    } catch (e) {
      // Handle error silently - we're checking periodically anyway
    }
  }

  void _startResendCooldownTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) {
          setState(() {
            _resendCooldown--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResendEmail = true;
          });
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    print("Inside resendVerificationEmail");
    if (!_canResendEmail) return;

    try {
      await _authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent again')),
        );

        setState(() {
          _canResendEmail = false;
          _resendCooldown = 60;
        });

        _startResendCooldownTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: ${e.toString()}')),
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LogoWidget(),
                        const SizedBox(height: 16),
                        Text(
                          'Verify Your Email',
                          style: AppTextStyles.heading,
                        ),
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.email_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'We sent a verification email to:',
                          style: AppTextStyles.subheading,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email,
                          style: AppTextStyles.subheading.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Please check your inbox and click the verification link to activate your account.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _isEmailVerified
                            ? CustomButton(
                          text: 'Proceed to Login',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                        )
                            : Column(
                          children: [

                            CustomButton(
                              text: _canResendEmail
                                  ? 'Resend Verification Email'
                                  : 'Resend Email in $_resendCooldown s',
                              onPressed: () {
                                if (_canResendEmail) {
                                  _resendVerificationEmail();
                                }
                              },
                            ),

                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: Text(
                                'Back to Login',
                                style: AppTextStyles.linkText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}