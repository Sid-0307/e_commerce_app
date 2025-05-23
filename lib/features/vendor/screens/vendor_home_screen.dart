// lib/features/vendor/screens/vendor_home_screen.dart

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
  const VendorHomeScreen({Key? key}) : super(key: key);

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ProductsTab(),
    const RequestsTab(),
    const ProfileTab(),
  ];

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
    return Scaffold(
      backgroundColor: AppColors.lightTertiary,
      // body: Stack(
      //   children: [
      //     // Blob positioned at the top
      //     Positioned(
      //       left: -100,
      //       top: -50,
      //       right: -100,
      //       child: _buildBlob1(),
      //     ),
          // Main content
      body:SafeArea(
            child: _tabs[_selectedIndex],
          ),
        // ],
      // ),
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