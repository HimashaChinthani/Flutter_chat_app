import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  static Future<void> createNotification(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['read'] = false;
    await _notificationsRef.add(data);
  }

  /// Create a chat invite notification
  static Future<void> createChatInviteNotification({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String sessionId,
  }) async {
    await createNotification({
      'type': 'chat_invite',
      'toUid': toUid,
      'fromUid': fromUid,
      'fromName': fromName,
      'sessionId': sessionId,
      'message': '$fromName wants to chat with you',
      'title': 'New Chat Request',
    });
  }

  /// Show an in-app alert notification
  static void showAlert(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onTap,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed:
              onTap ??
              () {
                print('Navigating to notifications...');
              },
        ),
      ),
    );
  }

  static Stream<QuerySnapshot> streamNotificationsFor(String uid) {
    return _notificationsRef
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream unread notifications count for badge
  static Stream<int> streamUnreadCountFor(String uid) {
    return _notificationsRef
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markRead(String docId) async {
    await _notificationsRef.doc(docId).update({'read': true});
  }

  static Future<void> delete(String docId) async {
    await _notificationsRef.doc(docId).delete();
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllReadFor(String uid) async {
    final unreadDocs = await _notificationsRef
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
