import 'package:e_commerce_app/core/widgets/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../../authentication/screens/login_screen.dart';
import '../../authentication/services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _aboutUsController;

  // Phone variables
  String _phoneNumber = '';
  String _countryCode = '+91'; // Default, will be updated from user model
  String _countryISOCode = 'IN';
  String? _phoneError;

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _aboutUsController = TextEditingController(text: user?.aboutUs ?? '');

    // Initialize phone information
    _phoneNumber = user?.phoneNumber ?? '';
    _countryCode = user?.countryCode ?? '+91';
    _countryISOCode = user?.countryISOCode ?? 'IN';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _aboutUsController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (_isEditing) {
      // If we're currently editing, toggle back to view mode without saving
      _initControllers(); // Reset controllers to original values
      setState(() {
        _phoneError = null;
      });
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Clear the user in the provider
      Provider.of<UserProvider>(context, listen: false).clearCurrentUser();

      final FirebaseAuth _auth = FirebaseAuth.instance;
      // Then sign out through the auth service
      await _auth.signOut();

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(initialScreen: 'login'),
        ),
            (route) => false, // Remove all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for phone number
    if (_phoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      // Prepare updated user data
      final updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneNumber,
        'countryCode': _countryCode,
        'countryISOCode':_countryISOCode,
        'address': _addressController.text.trim(),
        'aboutUs': _aboutUsController.text.trim(),
      };

      // Update in Firestore
      await _firestoreService.updateUserData(user.uid, updatedData);

      // Update Firebase Auth display name if changed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.displayName != _nameController.text.trim()) {
        await currentUser.updateDisplayName(_nameController.text.trim());
      }

      // Create updated UserModel using copyWith
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneNumber,
        countryCode: _countryCode,
        countryISOCode: _countryISOCode,
        address: _addressController.text.trim(),
        aboutUs: _aboutUsController.text.trim(),
      );

      // Update the UserProvider with the updated UserModel
      userProvider.updateLocalUserData(updatedUser);

      // Switch back to viewing mode
      setState(() {
        _isEditing = false;
        _phoneError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileForm(UserModel? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: AppTextStyles.heading1,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    onPressed: () => _handleLogout(context),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field
              _isEditing
                  ? CustomTextField(
                controller: _nameController,
                labelText: 'Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              )
                  : ProfileField(
                label: 'Name',
                value: user?.name ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Email field (always read-only)
              ProfileField(
                label: 'Email',
                value: user?.email ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Phone field
              _isEditing
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    initialCountryCode: user?.countryISOCode,
                    initialValue: user?.phoneNumber ?? '',
                    onChanged: (phone) {
                      _phoneNumber = phone.number;
                      _countryCode = phone.countryCode;
                      _countryISOCode = phone.countryISOCode;
                      setState(() {
                        _phoneError = null;
                      });
                    },
                  ),
                ],
              )
                  : ProfileField(
                label: 'Phone Number',
                value: (user?.phoneNumber.isNotEmpty == true && user?.countryCode.isNotEmpty == true)
                    ? user!.completePhoneNumber
                    : 'Not set',
              ),
              const SizedBox(height: 16),

              // Address field
              _isEditing
                  ? CustomTextField(
                controller: _addressController,
                labelText: 'Address (Optional)',
              )
                  : ProfileField(
                label: 'Address',
                value: (user?.address != null && user!.address!.isNotEmpty)
                    ? user.address!
                    : 'Not set',
              ),
              const SizedBox(height: 16),

              // About Us field
              _isEditing
                  ? CustomTextField(
                controller: _aboutUsController,
                labelText: 'About Us',
                // maxLines: 3,
              )
                  : ProfileField(
                label: 'About Us',
                value: (user?.aboutUs != null && user!.aboutUs!.isNotEmpty)
                    ? user.aboutUs!
                    : 'Not set',
              ),
              const SizedBox(height: 24),

              // Toggle button: Edit Profile / Save
              CustomButton(
                text: _isEditing ? 'Save' : 'Edit Profile',
                onPressed: _isEditing ? _saveProfile : _toggleEditing,
              ),

              // Cancel button (only shown in edit mode)
              if (_isEditing) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Cancel',
                  onPressed: _toggleEditing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final bool providerIsLoading = userProvider.isLoading;

    if (providerIsLoading || _isLoading) {
      return Stack(
        children: [
          _buildProfileForm(user), // Keep the form visible
          Container(
            color: Colors.white.withOpacity(0.7),
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  "Your data is being updated...",
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _buildProfileForm(user);
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}