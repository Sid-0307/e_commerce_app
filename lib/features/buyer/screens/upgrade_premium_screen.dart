// lib/features/buyer/screens/upgrade_premium_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../services/billing_service.dart';

void showUpgradePremiumBottomSheet(
    BuildContext context, {
      required VoidCallback onPurchaseSuccess,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => UpgradePremiumBottomSheet(
      onPurchaseSuccess: onPurchaseSuccess,
    ),
  );
}

class UpgradePremiumBottomSheet extends StatefulWidget {
  final VoidCallback onPurchaseSuccess;

  const UpgradePremiumBottomSheet({
    Key? key,
    required this.onPurchaseSuccess,
  }) : super(key: key);

  @override
  State<UpgradePremiumBottomSheet> createState() => _UpgradePremiumBottomSheetState();
}

class _UpgradePremiumBottomSheetState extends State<UpgradePremiumBottomSheet> {
  final BillingService _billingService = BillingService();
  bool _isLoading = false;

  void _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _billingService.purchasePremium(
        onSuccess: () {
          // Show success dialog
          _showSuccessDialog();
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
          });

          // Show error dialog
          _showErrorDialog(error);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('Failed to initiate purchase: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: EdgeInsets.fromLTRB(24, 10, 24, 0),
          actionsPadding: EdgeInsets.only(bottom: 16),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 12),
              Text(
                'Upgrade Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You now have unlimited access to contact suppliers!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                // Close success dialog
                Navigator.of(dialogContext).pop();

                // Close bottom sheet
                Navigator.of(context).pop();

                // Call success callback to retry the original request
                widget.onPurchaseSuccess();
              },
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 10),
              Text('Purchase Failed'),
            ],
          ),
          content: Text(
            error,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Premium icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                    borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 12),

              // Subtitle
              Text(
                'You\'ve reached your limit of 3 free requests',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 24),

              // Benefits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBenefitItem(
                      icon: Icons.all_inclusive,
                      title: 'Unlimited Requests',
                      subtitle: 'Contact as many suppliers as you want',
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Icons.priority_high,
                      title: 'Priority Support',
                      subtitle: 'Get faster responses from suppliers',
                    ),
                    // const SizedBox(height: 12),
                    // _buildBenefitItem(
                    //   icon: Icons.verified,
                    //   title: 'Verified Badge',
                    //   subtitle: 'Show suppliers you\'re a serious buyer',
                    // ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Price and button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, size: 20,color: AppColors.lightTertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Upgrade for ${_billingService.premiumProductPrice}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
        Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: AppColors.lightTertiary,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
          ),
          ),
        ],
      ),
    );
  }
}