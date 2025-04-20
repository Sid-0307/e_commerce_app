// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print('No user data found in Firestore for uid: $uid');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving user data: $e');
      throw e;
    }
  }

  // Update specific user fields
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user data: $e');
      throw e;
    }
  }
}