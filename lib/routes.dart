// lib/routes.dart

import 'package:e_commerce_app/features/admin/screens/admin_home_screen.dart';
import 'package:e_commerce_app/features/authentication/screens/splash_screen.dart';
import 'package:flutter/material.dart';

// Import all screens that need routes
import 'core/widgets/auth_wrapper.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/signup_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/vendor/models/product_model.dart';
import 'features/vendor/screens/add_edit_product_screen.dart';
import 'features/vendor/screens/vendor_home_screen.dart';

// Define route names as constants to avoid typos
class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String auth = '/auth'; // Replaces login, signup, forgot, etc.
  static const String signup = '/signup';
  static const String admin = '/admin';
  static const String forgotPassword = '/forgot-password';
  static const String vendorHome = '/vendor/home';
  static const String addProduct = '/vendor/product/add';
  static const String editProduct = '/vendor/product/edit';
}

// Define the route generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case AppRoutes.initial:
      //   return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.initial:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      // case AppRoutes.login:
      //   return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.admin:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());

      // case AppRoutes.signup:
      //   return MaterialPageRoute(builder: (_) => const SignupScreen());

      // case AppRoutes.forgotPassword:
      //   return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case AppRoutes.vendorHome:
        return MaterialPageRoute(builder: (_) => const VendorHomeScreen());

      case AppRoutes.addProduct:
        return MaterialPageRoute(builder: (_) => const AddEditProductScreen());

      case AppRoutes.editProduct:
      // Pass the product as an argument for editing
        final product = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => AddEditProductScreen(product: product),
        );

      default:
      // Return a 404 page or redirect to home
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}