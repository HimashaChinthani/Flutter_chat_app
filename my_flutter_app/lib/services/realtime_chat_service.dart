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
  }) async {
    await _ensureAuth();

    final sessionDoc = _firestore
        .collection(_sessionsCollection)
        .doc(sessionId);
    final sessionSnapshot = await sessionDoc.get();

    if (!sessionSnapshot.exists) {
      // Create new session
      await sessionDoc.set({
        'sessionId': sessionId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId],
        'createdBy': currentUserId,
        'isActive': true,
        'peerName': peerName,
        'lastMessage': '',
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } else {
      // Join existing session
      await sessionDoc.update({
        'participants': FieldValue.arrayUnion([currentUserId]),
        'isActive': true,
        'lastActivity': FieldValue.serverTimestamp(),
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
    final messageData = {
      'text': text.trim(),
      'senderId': currentUserId,
      'receiverId': receiverId ?? 'unknown',
      'sessionId': sessionId,
      'timestamp': now.toIso8601String(),
      'timestampMillis': now.millisecondsSinceEpoch, // For easier sorting
    };

    // Add message to Firestore
    await _firestore.collection(_messagesCollection).add(messageData);

    // Update session's last activity
    await _firestore.collection(_sessionsCollection).doc(sessionId).update({
      'lastMessage': text.trim(),
      'lastActivity': FieldValue.serverTimestamp(),
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

    // Delete all messages in the session
    final messagesQuery = await _firestore
        .collection(_messagesCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete the session
    batch.delete(_firestore.collection(_sessionsCollection).doc(sessionId));

    await batch.commit();
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
