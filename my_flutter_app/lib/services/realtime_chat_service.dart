import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class RealtimeChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name for chat messages
  static const String _messagesCollection = 'chat_messages';
  static const String _sessionsCollection = 'chat_sessions';

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Ensure user is authenticated
  static Future<void> _ensureAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Create or join a chat session
  static Future<void> createOrJoinSession(
    String sessionId, {
    String? peerName,
    String? otherUid,
    bool isSaved = false,
  }) async {
    await _ensureAuth();

    final sessionDoc = _firestore
        .collection(_sessionsCollection)
        .doc(sessionId);
    final sessionSnapshot = await sessionDoc.get();

    final myUid = currentUserId;
    final participants = (otherUid != null && myUid != null)
        ? [myUid, otherUid]
        : (myUid != null ? [myUid] : []);

    if (!sessionSnapshot.exists) {
      // Create new session with both users and isSaved flag
      await sessionDoc.set({
        'sessionId': sessionId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': participants,
        'createdBy': myUid,
        'isActive': true,
        'peerName': peerName,
        'lastMessage': '',
        'lastActivity': FieldValue.serverTimestamp(),
        'isSaved': isSaved,
      });
    } else {
      // Join existing session, ensure both users are present
      await sessionDoc.update({
        'participants': FieldValue.arrayUnion(participants),
        'isActive': true,
        'lastActivity': FieldValue.serverTimestamp(),
        if (isSaved) 'isSaved': true,
      });
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String sessionId,
    required String text,
    String? receiverId,
  }) async {
    await _ensureAuth();

    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    // If receiverId wasn't provided, try to derive it from the session participants
    String resolvedReceiver = receiverId ?? '';
    if (resolvedReceiver.isEmpty) {
      try {
        final sessionDoc = await _firestore
            .collection(_sessionsCollection)
            .doc(sessionId)
            .get();
        if (sessionDoc.exists) {
          final data = sessionDoc.data();
          final participants =
              (data?['participants'] as List?)?.cast<String>() ?? [];
          // pick the first participant that isn't the current user
          resolvedReceiver = participants.firstWhere(
            (p) => p != currentUserId,
            orElse: () => '',
          );
        }
      } catch (_) {
        resolvedReceiver = '';
      }
    }

    // If we still can't resolve, throw error
    if (resolvedReceiver.isEmpty) {
      throw Exception('Could not resolve receiverId for message');
    }

    final messageData = {
      'text': text.trim(),
      'senderId': currentUserId,
      'receiverId': resolvedReceiver,
      'sessionId': sessionId,
      'timestamp': now.toIso8601String(),
      'timestampMillis': now.millisecondsSinceEpoch, // For easier sorting
      'read': false, // unread by default
    };

    // Add message to Firestore
    await _firestore.collection(_messagesCollection).add(messageData);

    // Update session's last activity
    await _firestore.collection(_sessionsCollection).doc(sessionId).update({
      'lastMessage': text.trim(),
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  // Stream of unread count for a session for the current user
  static Stream<int> streamUnreadCountForSession(String sessionId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);
    return _firestore
        .collection(_messagesCollection)
        .where('sessionId', isEqualTo: sessionId)
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          // Only count messages that are unread and not sent by the current user
          int count = snap.docs
              .where((doc) => doc['read'] == false && doc['senderId'] != uid)
              .length;
          return count > 0 ? count - 1 : 0;
        });
  }

  // Mark all unread messages in a session as read for current user
  static Future<void> markSessionMessagesRead(String sessionId) async {
    // Only mark messages as read when user actually views them (e.g., scrolls to them)
    // Remove auto-marking on chat open
  }

  // Stream of chat sessions that have unread messages for current user
  static Stream<QuerySnapshot> streamSessionsWithUnreadForCurrentUser() {
    // Ensure we react to authentication state, then subscribe to unread messages
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();

      return _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .snapshots();
    });
  }

  // Get real-time stream of messages for a session - NO INDEXING NEEDED
  static Stream<List<ChatMessage>> getMessagesStream(String sessionId) {
    return _firestore
        .collection(_messagesCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
          final messages = <ChatMessage>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            messages.add(
              ChatMessage.fromFirestore(data, doc.id, currentUserId ?? ''),
            );
          }

          // Sort messages by timestamp on the client side
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          return messages;
        });
  }

  // End chat session
  static Future<void> endSession(String sessionId) async {
    await _ensureAuth();

    await _firestore.collection(_sessionsCollection).doc(sessionId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'endedBy': currentUserId,
    });
  }

  // Delete a chat session and its messages
  static Future<void> deleteSession(String sessionId) async {
    await _ensureAuth();
    final uid = currentUserId;
    if (uid == null) return;

    final sessionRef = _firestore
        .collection(_sessionsCollection)
        .doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    final sessionData = sessionSnap.data();
    final participants =
        (sessionData?['participants'] as List?)?.cast<String>() ?? [];
    final isSaved =
        sessionData?['isSaved'] == true || sessionData?['isSaved'] == 1;

    // If current user isn't part of the session, nothing to do
    if (!participants.contains(uid)) return;

    if (!isSaved) {
      // INSTANT CHAT: delete for both users immediately
      // Remove all participants
      await sessionRef.update({
        'participants': [],
        'lastActivity': FieldValue.serverTimestamp(),
      });
      // Delete all messages and session doc
      final messagesQuery = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .get();
      const int batchLimit = 500;
      final docs = messagesQuery.docs;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final end = (i + batchLimit < docs.length)
            ? i + batchLimit
            : docs.length;
        final batch = _firestore.batch();
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }
      await sessionRef.delete();
      return;
    }

    // SAVED CHAT: Remove only the current user from the participants array so the other
    // participant keeps their chat history. If no participants remain after
    // removal, perform a full cleanup (delete messages + session doc).
    await sessionRef.update({
      'participants': FieldValue.arrayRemove([uid]),
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Re-read session to inspect remaining participants
    final updatedSnap = await sessionRef.get();
    final updatedParticipants =
        (updatedSnap.data()?['participants'] as List?)?.cast<String>() ?? [];

    if (updatedParticipants.isEmpty) {
      // No participants left: delete all messages and the session doc.
      final messagesQuery = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .get();

      // Delete messages in chunks to respect the 500-op batch limit
      const int batchLimit = 500;
      final docs = messagesQuery.docs;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final end = (i + batchLimit < docs.length)
            ? i + batchLimit
            : docs.length;
        final batch = _firestore.batch();
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }

      await sessionRef.delete();
    }
  }

  // Get chat session info
  static Future<Map<String, dynamic>?> getSessionInfo(String sessionId) async {
    final doc = await _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  // Real-time stream for a session document
  static Stream<DocumentSnapshot> sessionStream(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots();
  }

  // Generate a unique session ID
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'chat_$random';
  }
}
