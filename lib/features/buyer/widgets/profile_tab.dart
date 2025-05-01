import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/hsCodeSearch_widget.dart';

class BuyerProfileTab extends StatefulWidget {
  const BuyerProfileTab({Key? key}) : super(key: key);

  @override
  State<BuyerProfileTab> createState() => _BuyerProfileTabState();
}

class _BuyerProfileTabState extends State<BuyerProfileTab> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;

  String _phoneNumber = '';
  String _countryCode = '+91';
  String _countryISOCode = 'IN';
  String? _phoneError;

  // HS Code preferences - using List<String?> to properly handle null values
  List<String?> _selectedHSCodes = [];
  List<String> _hsCodePreferences = [];

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final UserModel? userModel = await Provider.of<UserProvider>(context, listen: false).currentUser;

    _nameController = TextEditingController(text: userModel?.name ?? '');

    // Parse phone number to separate country code and number if exists
    _phoneNumber = userModel?.phoneNumber ?? '';
    _countryCode = userModel?.countryCode ?? '+91';
    _countryISOCode = userModel?.countryISOCode ?? 'IN';

    _addressController = TextEditingController(text: userModel?.address ?? '');

    // Initialize HS code preferences from user model
    _hsCodePreferences = List<String>.from(userModel?.hsCodePreferences ?? []);

    // Initialize selected HS codes with existing preferences and ensure it has right length
    _selectedHSCodes = List<String?>.from(_hsCodePreferences);

    // Make sure we have at least 3 slots for HS codes (which may be null)
    while (_selectedHSCodes.length < 3) {
      _selectedHSCodes.add(null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      final UserModel? userModel = userProvider.currentUser;

      if (userModel == null) {
        throw Exception('User not found');
      }

      // Filter out null values and collect only the HS codes as strings
      _hsCodePreferences = _selectedHSCodes
          .where((hsCode) => hsCode != null)
          .map((hsCode) => hsCode!) // Safe to use ! after filtering nulls
          .toList();

      print("HSCODE: ${_hsCodePreferences} \n\n Selected: ${_selectedHSCodes}");

      // Prepare updated user data
      final updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneNumber,
        'countryCode': _countryCode,
        'countryISOCode': _countryISOCode,
        'address': _addressController.text.trim(),
        'hsCodePreferences': _hsCodePreferences, // Add HS code preferences
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
        phoneNumber: _phoneNumber,
        countryCode: _countryCode,
        countryISOCode: _countryISOCode,
        address: _addressController.text.trim(),
        hsCodePreferences: _hsCodePreferences, // Add HS code preferences
      );

      // Refresh user data in the provider
      userProvider.updateLocalUserData(updatedUserModel);

      _hsCodePreferences = List<String>.from(updatedUserModel.hsCodePreferences);

      // Initialize selected HS codes with existing preferences and ensure it has right length
      _selectedHSCodes = List<String?>.from(_hsCodePreferences);

      // Make sure we have at least 3 slots for HS codes (which may be null)
      while (_selectedHSCodes.length < 3) {
        _selectedHSCodes.add(null);
      }

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

  // Build a widget to display the HS code preferences in view mode
  Widget _buildHSCodePreferenceList(List<String> hsCodes) {
    if (hsCodes.isEmpty) {
      return const Text('Not set',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: hsCodes.map((code) => Container(
        margin: EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.primary, width: 1.0),
        ),
        child: Text(
          code,
          style: AppTextStyles.body.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildProfileForm(UserModel? userModel) {
    print("Selected : ${_selectedHSCodes}");
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
              const SizedBox(height: 14),

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
                    initialCountryCode: userModel?.countryISOCode,
                    initialValue: userModel?.phoneNumber ?? '',
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
                value: (userModel?.phoneNumber.isNotEmpty == true && userModel?.countryCode.isNotEmpty == true)
                    ? userModel!.completePhoneNumber
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
              const SizedBox(height: 16),

              // HS Code Preferences
              _isEditing
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HS Code Preferences',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // First HS Code Preference
                  HSCodeSearchWidget(
                    labelText: 'Preference 1',
                    initialValue: _selectedHSCodes.isNotEmpty && _selectedHSCodes[0] != null
                        ? _selectedHSCodes[0]
                        : null,
                    onChanged: (hsCode) {
                      setState(() {
                        if (_selectedHSCodes.length > 0) {
                          _selectedHSCodes[0] = hsCode?.hscode;
                        } else {
                          _selectedHSCodes.add(hsCode?.hscode);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Second HS Code Preference
                  HSCodeSearchWidget(
                    labelText: 'Preference 2',
                    initialValue: _selectedHSCodes.length > 1 ? _selectedHSCodes[1] : null,
                    onChanged: (hsCode) {
                      setState(() {
                        if (_selectedHSCodes.length > 1) {
                          _selectedHSCodes[1] = hsCode?.hscode;
                        } else if (_selectedHSCodes.length == 1) {
                          _selectedHSCodes.add(hsCode?.hscode);
                        } else {
                          // If somehow we don't have an element at index 0
                          _selectedHSCodes = [null, hsCode?.hscode];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Third HS Code Preference
                  HSCodeSearchWidget(
                    labelText: 'Preference 3',
                    initialValue: _selectedHSCodes.length > 2 ? _selectedHSCodes[2] : null,
                    onChanged: (hsCode) {
                      setState(() {
                        if (_selectedHSCodes.length > 2) {
                          _selectedHSCodes[2] = hsCode?.hscode;
                        } else if (_selectedHSCodes.length == 2) {
                          _selectedHSCodes.add(hsCode?.hscode);
                        } else if (_selectedHSCodes.length == 1) {
                          _selectedHSCodes.addAll([null, hsCode?.hscode]);
                        } else {
                          // If somehow we have no elements
                          _selectedHSCodes = [null, null, hsCode?.hscode];
                        }
                      });
                    },
                  ),
                ],
              )
                  : ProfileField(
                label: 'HS Code Preferences',
                customChild: _buildHSCodePreferenceList(userModel?.hsCodePreferences ?? []),
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
  final Widget? customChild;

  const ProfileField({
    Key? key,
    required this.label,
    this.value = '',
    this.customChild,
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
          if (customChild != null)
            customChild!
          else
            Text(
              value,
              style: AppTextStyles.body,
            ),
        ],
      ),
    );
  }
}