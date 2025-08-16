import 'package:cloud_firestore/cloud_firestore.dart';

class CrudServices {
  final FirebaseFirestore service;
  CrudServices({FirebaseFirestore? firestore})
    : service = firestore ?? FirebaseFirestore.instance;

  // Insert a user into 'users' collection with a specific document id.
  // Returns true on success, false on failure.
  Future<bool> insertUser({
    required String userId,
    required String name,
  }) async {
    try {
      await service.collection('users').doc(userId).set({
        'id': userId,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      return true;
    } catch (e) {
      // Log error if needed
      return false;
    }
  }

  // Insert a user into 'users' collection with an auto-generated document id.
  // Returns the generated document id on success, or null on failure.
  Future<String?> insertUserAuto({required String name}) async {
    try {
      final docRef = await service.collection('users').add({
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get a user from 'users' collection by id. Returns a Map or null.
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await service.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
