import 'package:flutter/material.dart';
import '../../../core/background_decorations.dart';
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
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  String _finalPhoneController = '';
  bool _isLoading = false;
  String _userType = 'buyer'; // Default type
  String _countryCode = '+91'; // Default country code (IND)

  final List<String> _userTypes = ['buyer', 'seller']; // Define the list of user types
  final List<String> _countryCodes = [
    '+1', '+44', '+91', '+81', '+86', '+61', '+49', '+33', '+7', '+55'
  ]; // Common country codes

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Combine country code with phone number
        _finalPhoneController = '$_countryCode${_phoneController.text.trim()}';

        // Sign up the user
        final user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _userType,
          _finalPhoneController,
        );

        print("sIGNUP DONE");
        print(user);

        // Send email verification
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please verify your email')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup failed: ${e.toString()}')),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                          'Sign Up',
                          style: AppTextStyles.heading,
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
                              // Phone number field with country code
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                
                                children: [
                                  // Country code dropdown
                                  Container(
                                    width:80,
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColors.tertiary.withOpacity(0.15),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: DropdownButton<String>(
                                        value: _countryCode,
                                        isExpanded: true,
                                        underline: Container(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _countryCode = newValue;
                                            });
                                          }
                                        },
                                        items: _countryCodes.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Phone number input
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneController,
                                      labelText: "Phone number",
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (value.length != 10) {
                                          return 'Phone number must be 10 digits';
                                        }
                                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                          return 'Only digits are allowed';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
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
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Text('Account Type', style: AppTextStyles.subheading),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _userType,
                                  isExpanded: true,
                                  underline: Container(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _userType = newValue;
                                      });
                                    }
                                  },
                                  items: _userTypes.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.substring(0, 1).toUpperCase() + value.substring(1)),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : CustomButton(
                                text: 'Create Account',
                                onPressed: _signup,
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