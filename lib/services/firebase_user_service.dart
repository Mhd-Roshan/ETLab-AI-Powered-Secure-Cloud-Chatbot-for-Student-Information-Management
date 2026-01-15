import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseUserService {
  static const String _usersCollection = 'users';
  
  late final FirebaseFirestore _firestore;
  
  FirebaseUserService() {
    _firestore = FirebaseFirestore.instance;
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        // Ensure the document ID is included in the user data
        data['id'] = doc.id;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (snapshot.exists) {
        return User.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Create new user
  Future<bool> createUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson());
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(user.toJson());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Get all users with specific role
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Get users by college
  Future<List<User>> getUsersByCollege(String collegeCode) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_usersCollection)
          .where('collegeCode', isEqualTo: collegeCode)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching users by college: $e');
      return [];
    }
  }

  // Delete user (soft delete - mark as inactive)
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'isActive': false});
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Verify credentials (placeholder - implement authentication)
  Future<User?> verifyCredentials(
      String username, String password, String collegeName) async {
    // This is a placeholder. In production, use proper authentication.
    // For now, just return the user if they exist
    return getUserByUsername(username);
  }

  // Update last login timestamp
  Future<bool> updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'lastLogin': DateTime.now().toIso8601String()});
      return true;
    } catch (e) {
      print('Error updating last login: $e');
      return false;
    }
  }
}
