import 'package:another_flushbar/flushbar.dart';
import 'package:e_commerce_app/core/widgets/auth_wrapper.dart';
import 'package:e_commerce_app/features/admin/screens/admin_home_screen.dart';
import 'package:e_commerce_app/features/vendor/screens/vendor_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/background_decorations.dart';
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

  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in as soon as the login screen initializes
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserModel? user = await _authService.getCurrentUser();

      if (user != null && mounted) {
        // Set user in provider
        await Provider.of<UserProvider>(context, listen: false).setCurrentUser(
            user);

        // Navigate based on user type
        if (mounted) {
          // Navigate based on user type
          if (user.userType == 'Seller') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const VendorHomeScreen(),
              ),
            );
          } else if (user.userType == 'Buyer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BuyerHomeScreen(),
              ),
            );
          } else if (user.userType == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminHomeScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Error checking user, but we don't need to show any message
      // Just let the user continue to the login screen
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show a sleek notification using Flushbar
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
          fontSize: 12, // 👈 Adjust this value as needed
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

  // Parse Firebase error codes and return user-friendly messages

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
          _showNotification(
            title: 'Login Successsful',
            message: 'Redirecting to your dashboard',
            backgroundColor: Colors.green.shade700,
            icon: Icons.check_circle,
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
              } else if (user.userType == 'Admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen(),
                  ),
                );
              }
            }
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = AuthService().getMessageFromErrorCode(e);
          print('Error code ${e}');
          // Special case for email verification
          if (errorMessage == 'email-not-verified') {
            // _showVerificationDialog()
            _showNotification(
              title: 'Email Not Verified',
              message: 'Please check your inbox for the verification link',
              backgroundColor: Colors.orange.shade800,
              icon: Icons.mark_email_unread,
              durationInSeconds: 3,
            );
          }else if(e is FirebaseAuthException && e.code == 'network-request-failed'){
            _showNotification(
              title: 'Login Failed',
              message: errorMessage,
              backgroundColor: Colors.red.shade700,
              icon: Icons.signal_wifi_off,
            );
          }else
           {
            _showNotification(
              title: 'Login Failed',
              message: errorMessage,
              backgroundColor: Colors.red.shade700,
              icon: Icons.error_outline,
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

  // void _showVerificationDialog() {
  // Future.delayed(Duration(milliseconds: 500), () {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Email Verification Required'),
  //       content: Text('You need to verify your email before logging in. Would you like to resend the verification email?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //           child: Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             _resendVerificationEmail();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.primary,
  //           ),
  //           child: Text('Resend Email'),
  //         ),
  //       ],
  //     ),
  //   );
  // });
  // }

  // Future<void> _resendVerificationEmail() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     // First try to sign in to get the user authenticated
  //     await _authService.signIn(
  //       _emailController.text.trim(),
  //       _passwordController.text.trim(),
  //     );
  //
  //     // Then send verification email
  //     await _authService.sendEmailVerification();
  //
  //     if (mounted) {
  //       _showNotification(
  //         title: 'Email Sent',
  //         message: 'Verification email has been sent successfully. Please check your inbox.',
  //         backgroundColor: Colors.green.shade700,
  //         icon: Icons.email,
  //       );
  //
  //       // Navigate to verification screen
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => EmailVerificationScreen(
  //             email: _emailController.text.trim(),
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       String errorMessage = _getMessageFromErrorCode(e);
  //
  //       _showNotification(
  //         title: 'Verification Failed',
  //         message: 'Failed to send verification email: $errorMessage',
  //         backgroundColor: Colors.red.shade700,
  //         icon: Icons.error_outline,
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.lightTertiary,
      body: AuthWrapper(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthCard(
                  child: Column(
                    children: [
                      // const LogoWidget(),
                      const SizedBox(height: 16),
                      // Title inside the AuthCard
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
                            const SizedBox(height: 16),
                            CustomTextField(
                              labelText: 'Password',
                              controller: _passwordController,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
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