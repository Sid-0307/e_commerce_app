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

  // Get all users from Firestore
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      throw e;
    }
  }

  // Delete user by uid
  Future<void> deleteUser(String uid) async {
    try {
      // First, we might want to delete any related data
      // For example, if users have specific subcollections or references

      // Then delete the user document itself
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // Optional: Get users with pagination for better performance with large datasets
  Future<List<UserModel>> getPaginatedUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('users').limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting paginated users: $e');
      throw e;
    }
  }

  // Optional: Filter users by type (buyer/seller)
  Future<List<UserModel>> getUsersByType(String userType) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: userType)
          .get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting users by type: $e');
      throw e;
    }
  }

  // Optional: Search users by name or email
  Future<List<UserModel>> searchUsers(String searchTerm) async {
    try {
      // Firebase doesn't support direct text search, so we need to use startAt/endAt
      // This will match from the beginning of the field
      String searchTermLower = searchTerm.toLowerCase();
      String searchTermHigher = searchTermLower + '\uf8ff';

      // Search by name
      QuerySnapshot nameSnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: searchTermLower)
          .where('name', isLessThanOrEqualTo: searchTermHigher)
          .get();

      // Search by email
      QuerySnapshot emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTermLower)
          .where('email', isLessThanOrEqualTo: searchTermHigher)
          .get();

      // Combine and remove duplicates
      Set<String> processedIds = {};
      List<UserModel> results = [];

      // Process name matches
      for (var doc in nameSnapshot.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          results.add(UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ));
        }
      }

      // Process email matches
      for (var doc in emailSnapshot.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          results.add(UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ));
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      throw e;
    }
  }
}