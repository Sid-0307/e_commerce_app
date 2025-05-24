// lib/features/vendor/screens/vendor_home_screen.dart

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/auth_wrapper.dart';
import '../widgets/products_tab.dart';
import '../widgets/requests_tab.dart';
import '../widgets/profile_tab.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';

class VendorHomeScreen extends StatefulWidget {
  final String? flushbarMessage;

  const VendorHomeScreen({Key? key,this.flushbarMessage}) : super(key: key);

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _selectedIndex = 0;
  bool _hasShownFlushbar = false;

  @override
  void initState() {
    super.initState();
    if (widget.flushbarMessage == null) {
      _hasShownFlushbar = true;
    }
  }

  final List<Widget> _tabs = [
    const ProductsTab(),
    const RequestsTab(),
    const ProfileTab(),
  ];

  void _showSuccessFlushbar(BuildContext context,String message) {
    if (!mounted) return;

    Flushbar(
      message: message,
      icon: Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 24,
      ),
      duration: Duration(seconds: 3),
      leftBarIndicatorColor: Colors.green,
      backgroundColor: Colors.green.shade600,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      messageColor: Colors.white,
      messageSize: 14,
      animationDuration: Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }


  Widget _buildBlob1() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.7),
            AppColors.secondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flushbarMessage != null && !_hasShownFlushbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessFlushbar(context, widget.flushbarMessage!);
      });
      _hasShownFlushbar = true;
    }
    return Scaffold(
      backgroundColor: AppColors.lightTertiary,
      body:SafeArea(
            child: _tabs[_selectedIndex],
          ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}