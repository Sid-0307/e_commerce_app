import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/user_persistence.dart';

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

      UserModel currentuser = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          user.uid
      );

      // Save user for persistence
      await UserPersistence.saveUser(currentuser);

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
      String phoneNumber,
      String countryCode, // Added country code parameter
      String countryISOCode,
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
        'countryCode': countryCode, // Store country code separately
        'countryISOCode':countryISOCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user!.updateDisplayName(name);
      await sendEmailVerification();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Check if there's a logged-in user in SharedPreferences
      UserModel? user = await UserPersistence.getUser();
      if (user != null) {
        // Verify with Firebase Auth current user
        User? firebaseUser = _auth.currentUser;
        if (firebaseUser != null && firebaseUser.uid == user.uid) {
          // User is authenticated on Firebase and data is in local storage
          return user;
        } else {
          // Mismatch or Firebase auth is gone, clear local data
          await UserPersistence.clearUser();
        }
      }
      return null;
    } catch (e) {
      await UserPersistence.clearUser();
      return null;
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

  String getMessageFromErrorCode(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later';
        case 'network-request-failed':
          return 'Please check your internet connection and try again.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'account-exists-with-different-credential':
          return 'An account exists with a different sign-in method. Try another method.';
        case 'invalid-credential':
          return 'The login credentials are invalid. Please try again.';
        case 'invalid-verification-code':
          return 'Invalid verification code. Please try again.';
        case 'invalid-verification-id':
          return 'Invalid verification. Please request a new verification.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    } else if (error.toString().contains('verify your email')) {
      return 'email-not-verified';
    }

    return 'An unexpected error occurred. Please try again later.';
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