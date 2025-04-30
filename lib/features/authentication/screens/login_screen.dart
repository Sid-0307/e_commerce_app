import 'package:another_flushbar/flushbar.dart';
import 'package:e_commerce_app/features/vendor/screens/vendor_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/background_decorations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../buyer/screens/buyer_home_screen.dart';
import '../widgets/auth_card.dart';
import '../widgets/logo_widget.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserModel? user = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          await Provider.of<UserProvider>(context, listen: false)
              .setCurrentUser(user);
        }

        // Navigate based on user type
        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              // Check user type and redirect accordingly
              if (user.userType == 'Seller') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorHomeScreen(),
                  ),
                );
              } else if (user.userType == 'Buyer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuyerHomeScreen(),
                  ),
                );
              }
            }
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();

          // Check if the error is related to email verification
          if (errorMessage.contains('verify your email')) {
            _showVerificationDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed: $errorMessage')),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  void _showVerificationDialog() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email Not Verified: Please check your inbox for the verification link.')),
      );

    // Flushbar(
    //   title: 'Email Not Verified',
    //   message: 'Please check your inbox for the verification link.',
    //   duration: Duration(seconds: 3),
    //   backgroundColor: Colors.red,
    //   flushbarPosition: FlushbarPosition.TOP,
    // ).show(context);

        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       Navigator.of(context).pop();
        //       // Navigate to verification screen
        //       Navigator.pushReplacement(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => EmailVerificationScreen(
        //             email: _emailController.text.trim(),
        //           ),
        //         ),
        //       );
        //     },
        //     child: const Text('Resend Email'),
        //   ),
        // ],
  }

  Future<void> _resendVerificationEmail() async {
    try {
      // First try to sign in to get the user authenticated
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Then send verification email
      await _authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );

        // Navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
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
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: BackgroundDecorations(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Only Logo outside the AuthCard
                // Everything else inside the AuthCard
                AuthCard(
                  child: Column(
                    children: [
                      const LogoWidget(),
                      const SizedBox(height: 24),
                      // Title inside the AuthCard
                      Text(
                        'Log In',
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: 24),
                      // Form elements
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              labelText: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
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
                            const SizedBox(height: 16),
                            CustomTextField(
                              labelText: 'Password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : CustomButton(
                              text: 'Log In',
                              onPressed: _login,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.linkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "Don't have an account?" text and Sign up button inside the AuthCard
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
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
    );
  }
}