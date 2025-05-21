import 'package:e_commerce_app/core/providers/user_persistence.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Set user data after login
  Future<void> setCurrentUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch additional user data from Firestore
      final userData = await _firestoreService.getUserData(user.uid);

      _currentUser = UserModel(
        uid: user.uid,
        email: user.email,
        name: userData?['name'] ?? user.name,
        userType: userData?['userType'] ?? user.userType, // Add userType
        phoneNumber: userData?['phoneNumber'] ?? user.phoneNumber,
        countryCode: userData?['countryCode'] ?? user.countryCode,
        countryISOCode: userData?['countryISOCode'] ?? user.countryISOCode,
        address: userData?['address'] ?? user.address,
        hsCodePreferences: userData?['hsCodePreferences'] ?? user.hsCodePreferences,
      );
      await UserPersistence.saveUser(user);

    } catch (e) {
      // If Firestore fetch fails, use the provided user model
      _currentUser = user;
      print('Error fetching additional user data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear user data on logout
  void clearCurrentUser() async{
    _currentUser = null;
    await UserPersistence.clearUser();
    notifyListeners();
  }


  Future<void> loadUserFromStorage() async {
    // Load user from persistent storage if available
    final user = await UserPersistence.getUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // Update local user data after profile edit
  void updateLocalUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    await UserPersistence.saveUser(_currentUser!);
    notifyListeners();
  }
}