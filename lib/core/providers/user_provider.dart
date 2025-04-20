import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Set user data after login
  Future<void> setCurrentUser(User firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch additional user data from Firestore
      final userData = await _firestoreService.getUserData(firebaseUser.uid);

      _currentUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: userData?['name'] ?? firebaseUser.displayName ?? '',
        phoneNumber: userData?['phoneNumber'] ?? firebaseUser.phoneNumber ?? '',
        address: userData?['address'],
      );
    } catch (e) {
      // If Firestore fetch fails, at least save basic Firebase Auth data
      _currentUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
      );
      print('Error fetching additional user data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear user data on logout
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }

  // Update local user data after profile edit
  // This can be useful if you don't want to reload from Firebase every time
  void updateLocalUserData(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}