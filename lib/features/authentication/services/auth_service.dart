import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        return null;
      }

      // Check if email is verified
      if (!user.emailVerified) {
        throw Exception('Please verify your email before logging in');
      }

      // Fetch user data from Firestore to get userType and other fields
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!, user.uid);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }
  Future<User?> signUp(
      String email,
      String password,
      String name,
      String userType,
      String phoneNumber
      ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      await _firestore.collection('users').doc(user?.uid).set({
        'email': email,
        'name': name,
        'userType': userType,
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user!.updateDisplayName(name);
      await sendEmailVerification();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    print("In sendEmail verification");
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else if (user == null) {
      throw Exception('No user is currently signed in');
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();

    if (user.emailVerified) {
      await _firestore.collection('users').doc(user.uid).update({
        'isEmailVerified': true,
      });
      return true;
    }

    return false;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}