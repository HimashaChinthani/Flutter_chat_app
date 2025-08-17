import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class UserService {
  // Use a getter to avoid stale instances across hot reloads
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  // Create a new user in Firebase
  static Future<User> createUser({required String name}) async {
    try {
      // Ensure there's an authenticated user (anonymous is fine)
      final auth = fb_auth.FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final String userId = auth.currentUser!.uid;

      // Create user object
      final user = User(id: userId, name: name, createdAt: DateTime.now());

      // Save user to Firestore under "Users/<uid>" (aligns with secure rules)
      await _usersRef.doc(userId).set(user.toMap(), SetOptions(merge: true));

      return user;
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to create user: [${e.plugin}/${e.code}] ${e.message}',
      );
    } catch (e) {
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      throw Exception('Failed to create user: $e (auth uid: ${uid ?? 'none'})');
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
