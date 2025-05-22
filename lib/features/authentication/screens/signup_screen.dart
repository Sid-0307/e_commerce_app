import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/auth_wrapper.dart';
import '../../../core/widgets/background_decorations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../widgets/auth_card.dart';
import '../widgets/logo_widget.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Update phone handling
  String _phoneNumber = '';
  String _countryCode = '+91'; // Default country code (IND)
  String _countryISOCode = 'IN';

  final _authService = AuthService();
  String? _phoneError = null;

  // Add a boolean to track terms and conditions acceptance
  bool _acceptedTerms = false;

  bool _isLoading = false;
  String _userType = 'Buyer'; // Default type

  final List<String> _userTypes = ['Buyer', 'Seller']; // Define the list of user types

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to show notifications using Flushbar
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
      padding: const EdgeInsets.fromLTRB(18,16,10,16),
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

  Future<void> _signup() async {
    if (_formKey.currentState!.validate() && _acceptedTerms) {
      setState(() {
        _isLoading = true;
      });
      try {
        if (_phoneNumber.isEmpty) {
          setState(() {
            _phoneError = 'Please enter your phone number';
            _isLoading = false;
          });
          return;
        }

        // Sign up the user with separate phone number and country code
        final user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _userType,
          _phoneNumber,
          _countryCode, // Pass country code separately
          _countryISOCode,
        );

        // Send email verification
        if (mounted) {
          // Show success message
          _showNotification(
            title: 'Success',
            message: 'Account created! Please verify your email',
            backgroundColor: Colors.green,
            icon: Icons.check_circle_outline,
            durationInSeconds: 3,
          );

          // Navigate to email verification screen
          Navigator.pushReplacement(
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
          String errorMessage = AuthService().getMessageFromErrorCode(e);

          // Set appropriate icon and color based on error type
          IconData errorIcon;
          Color errorColor;

          if (e is FirebaseAuthException) {
            // Network related errors
            if (e.code == 'network-request-failed') {
              errorIcon = Icons.signal_wifi_off;
              errorColor = Colors.red.shade700;
            }
            // User input related errors
            else if (['invalid-email', 'weak-password', 'email-already-in-use'].contains(e.code)) {
              errorIcon = Icons.warning_amber_rounded;
              errorColor = Colors.red.shade700;
            }
            // Authentication failures
            else {
              errorIcon = Icons.error_outline;
              errorColor = Colors.red.shade700;
            }
          } else {
            // Generic error
            errorIcon = Icons.error_outline;
            errorColor = Colors.red.shade700;
          }

          _showNotification(
            title: 'Signup Failed',
            message: errorMessage,
            backgroundColor: errorColor,
            icon: errorIcon,
            durationInSeconds: 3,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_acceptedTerms) {
      _showNotification(
        title: 'Terms Required',
        message: 'Please accept the terms and conditions to continue.',
        backgroundColor: Colors.orangeAccent,
        icon: Icons.gavel,
        durationInSeconds: 3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: AuthWrapper(
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
                        // const LogoWidget(),
                        const SizedBox(height: 8),
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
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomTextField(
                                labelText: 'Name',
                                controller: _nameController,
                                prefixIcon: const Icon(Icons.person_outline),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
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
                              IntlPhoneField(
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  labelStyle: TextStyle(
                                    color: AppColors.black.withOpacity(0.6),
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  filled: true,
                                  fillColor: AppColors.tertiary.withOpacity(0.15),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red, width: 1.0),
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: AppColors.primary.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  counterText: '',
                                  errorText: _phoneError,
                                ),
                                initialCountryCode: 'IN',
                                onChanged: (phone) {
                                  // Store phone number and country code separately
                                  _phoneNumber = phone.number;
                                  _countryCode = phone.countryCode;
                                  _countryISOCode = phone.countryISOCode;
                                  setState(() {
                                    _phoneError = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 16),
                              CustomTextField(
                                labelText: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField2<String>(
                                isExpanded: true,
                                value: _userType,
                                decoration: InputDecoration(
                                  labelText: '  Account Type',
                                  labelStyle: TextStyle(
                                    color: AppColors.black.withOpacity(0.6),
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  filled: true,
                                  fillColor: AppColors.tertiary.withOpacity(0.15),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red, width: 1.0),
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: AppColors.primary.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                items: _userTypes
                                    .map((role) => DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _userType = value!;
                                  });
                                },
                                dropdownStyleData: DropdownStyleData(
                                  elevation: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.lightTertiary, // Same as your field background
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Terms and conditions checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    activeColor: AppColors.primary,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                                  ),
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'I agree to the ',
                                          style: TextStyle(color: AppColors.black,fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final Uri url = Uri.parse('https://www.massiveitsolutions.com/policy');
                                              await launchUrl(url);
                                            },
                                            child: Text(
                                              'Terms and Conditions',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : CustomButton(
                                text: 'Create Account',
                                onPressed: _signup, // Now we handle the terms check inside the _signup method
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Log in',
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