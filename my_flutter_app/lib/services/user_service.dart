import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('Users');

  // Create a new user in Firebase
  static Future<User> createUser({required String name}) async {
    try {
      // Generate a unique user ID via Firestore auto ID
      final String userId = _usersRef.doc().id;

      // Create user object
      final user = User(id: userId, name: name, createdAt: DateTime.now());

      // Save user to Firestore under "Users" collection
      await _usersRef.doc(userId).set(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get a user by ID
  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user information
  static Future<void> updateUser(User user) async {
    try {
      await _usersRef.doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete a user
  static Future<void> deleteUser(String userId) async {
    try {
      await _usersRef.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
