import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class UserService {
  static final DatabaseReference _usersRef = FirebaseDatabase.instance.ref(
    'users',
  );

  // Create a new user in Firebase
  static Future<User> createUser({required String name}) async {
    try {
      // Generate a unique user ID
      final String userId = _usersRef.push().key!;

      // Create user object
      final user = User(id: userId, name: name, createdAt: DateTime.now());

      // Save user to Firebase
      await _usersRef.child(userId).set(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get a user by ID
  static Future<User?> getUser(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user information
  static Future<void> updateUser(User user) async {
    try {
      await _usersRef.child(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete a user
  static Future<void> deleteUser(String userId) async {
    try {
      await _usersRef.child(userId).remove();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
