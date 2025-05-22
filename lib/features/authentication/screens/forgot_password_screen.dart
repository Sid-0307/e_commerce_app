import 'package:e_commerce_app/core/widgets/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../../../core/widgets/background_decorations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../widgets/auth_card.dart';
import '../widgets/logo_widget.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showNotification({
    required String title,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    int durationInSeconds = 3,
  }) {
    // Always dismiss keyboard
    FocusScope.of(context).unfocus();

    // Show notification
    Flushbar(
      title: title,
      messageText: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
      duration: Duration(seconds: durationInSeconds),
      backgroundColor: backgroundColor ?? AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        icon ?? Icons.info_outline,
        color: Colors.white,
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 5),
          blurRadius: 8.0,
        )
      ],
    ).show(context);
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.resetPassword(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = true;
          });
        }
      }
      catch (e) {
        if (mounted) {
          final errorMessage = _authService.getMessageFromErrorCode(e);
          if(e is FirebaseAuthException && e.code == 'network-request-failed') {
            _showNotification(
              title: 'Login Failed',
              message: errorMessage,
              backgroundColor: Colors.red.shade700,
              icon: Icons.signal_wifi_off,
            );
          }
          else {
            _showNotification(
              title: 'Password Reset Failed',
              message: errorMessage,
              backgroundColor: Colors.red.shade700,
              icon: Icons.error_outline,
            );
          }
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: AuthWrapper(
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  AuthCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'MLLIG',
                          style: AppTextStyles.appName.copyWith(
                            foreground: Paint()..color = AppColors.primary,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: AppColors.tertiary.withOpacity(0.6),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_emailSent)
                          Column(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 72,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Reset Email Sent',
                                style: AppTextStyles.subheading,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'We\'ve sent a password reset link to ${_emailController.text}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Back to Login',
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          )
                        else
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enter your email and we\'ll send you a link to get back into your account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                CustomTextField(
                                  labelText: 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : CustomButton(
                                  text: 'Reset Password',
                                  onPressed: _resetPassword,
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Back to Login',
                                      style: AppTextStyles.linkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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