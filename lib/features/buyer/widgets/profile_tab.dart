// lib/features/buyer/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart'; // Import UserModel

class BuyerProfileTab extends StatefulWidget {
  const BuyerProfileTab({Key? key}) : super(key: key);

  @override
  State<BuyerProfileTab> createState() => _BuyerProfileTabState();
}

class _BuyerProfileTabState extends State<BuyerProfileTab> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Country code selection
  String _selectedCountryCode = '+1'; // Default to US

  // List of country codes for dropdown
  final List<String> _countryCodes = [
    '+1', '+44', '+91', '+61', '+81', '+86', '+49', '+33', '+7', '+55'
  ];

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final UserModel? userModel = Provider.of<UserProvider>(context, listen: false).currentUser;

    _nameController = TextEditingController(text: userModel?.name ?? '');

    // Parse phone number to separate country code and number if exists
    if (userModel?.phoneNumber != null && userModel!.phoneNumber.isNotEmpty) {
      // Check if the phone number already contains a country code
      String phoneNumber = userModel.phoneNumber;
      // Find the country code from the phone number
      String countryCode = _countryCodes.firstWhere(
            (code) => phoneNumber.startsWith(code),
        orElse: () => '+1', // Default to +1 if not found
      );

      // Remove country code from phone number if it exists
      String number = phoneNumber.startsWith('+')
          ? phoneNumber.substring(countryCode.length)
          : phoneNumber;

      _phoneController = TextEditingController(text: number);
      _selectedCountryCode = countryCode;
    } else {
      _phoneController = TextEditingController();
    }

    _addressController = TextEditingController(text: userModel?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (_isEditing) {
      // If we're currently editing, toggle back to view mode without saving
      _initControllers(); // Reset controllers to original values
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

      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final UserModel? userModel = userProvider.currentUser;

      if (userModel == null) {
        throw Exception('User not found');
      }

      // Combine country code and phone number
      final fullPhoneNumber = _selectedCountryCode + _phoneController.text.trim();

      // Prepare updated user data
      final updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': fullPhoneNumber,
        'address': _addressController.text.trim(),
      };

      // Update in Firestore
      await _firestoreService.updateUserData(userModel.uid, updatedData);

      // Update Firebase Auth display name if changed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.displayName != _nameController.text.trim()) {
        await currentUser.updateDisplayName(_nameController.text.trim());
      }

      // Create updated UserModel
      final updatedUserModel = userModel.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        address: _addressController.text.trim(),
      );

      // Refresh user data in the provider
      userProvider.updateLocalUserData(updatedUserModel);

      // Switch back to viewing mode
      setState(() {
        _isEditing = false;
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

  Widget _buildProfileForm(UserModel? userModel) {
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

              // Avatar and name row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      userModel?.name?.isNotEmpty == true
                          ? userModel!.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel?.name ?? 'Buyer',
                        style: AppTextStyles.heading1,
                      ),
                      Text(
                        userModel?.userType.capitalize() ?? 'Buyer Account',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 14),
              const Divider(),
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
                value: userModel?.name ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Email field (always read-only)
              ProfileField(
                label: 'Email',
                value: userModel?.email ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Phone field
              _isEditing
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country code dropdown
                      Container(
                        height: 56, // Match the height of CustomTextField
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.tertiary.withOpacity(0.15),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCountryCode = newValue!;
                                });
                              },
                              isDense: true,
                              items: _countryCodes.map<
                                  DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Phone number input field
                      Expanded(
                        child: CustomTextField(
                          controller: _phoneController,
                          labelText: 'Phone number',
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
                ],
              )
                  : ProfileField(
                label: 'Phone Number',
                value: userModel?.phoneNumber?.isNotEmpty == true
                    ? userModel!.phoneNumber
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
                value: (userModel?.address != null && userModel!.address!.isNotEmpty)
                    ? userModel.address!
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
    final UserModel? userModel = userProvider.currentUser;
    final bool providerIsLoading = userProvider.isLoading;

    if (providerIsLoading || _isLoading) {
      return Stack(
        children: [
          _buildProfileForm(userModel), // Keep the form visible
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
    return _buildProfileForm(userModel);
  }
}

// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
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