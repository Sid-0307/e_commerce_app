// lib/features/buyer/screens/buyer_home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../widgets/connection_tab.dart';
import '../widgets/products_tab.dart';
import '../widgets/profile_tab.dart';
// import '../tabs/connections_tab.dart';
// import '../tabs/messages_tab.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const BuyerProductsTab(),
    const BuyerConnectionsTab(),
    // const BuyerMessagesTab(),
    const BuyerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page_outlined), // Thin-lined version for inactive
            activeIcon: Icon(Icons.request_page),    // Filled version for active
            label: 'Requests',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.message_outlined),
          //   activeIcon: Icon(Icons.message),
          //   label: 'Messages',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}