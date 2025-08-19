import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Invite flow implemented on top of Firestore.
/// Collection: `chat_invites`.
/// Document id will be the sessionId so both sides can easily listen.
class InviteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference get _invitesRef =>
      _firestore.collection('chat_invites');

  static Future<void> _ensureAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Create or update an invite for [sessionId] targeted at [toUid].
  /// Uses [fromUid]/[fromName] metadata. Document id = sessionId.
  static Future<void> sendInvite({
    required String sessionId,
    required String toUid,
    required String toName,
    String? fromUid,
    String? fromName,
  }) async {
    await _ensureAuth();

    final senderUid = fromUid ?? _auth.currentUser?.uid;

    final payload = {
      'sessionId': sessionId,
      'toUid': toUid,
      'toName': toName,
      'fromUid': senderUid,
      'fromName': fromName ?? 'Someone',
      'status': 'pending', // pending | accepted | rejected
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _invitesRef.doc(sessionId).set(payload, SetOptions(merge: true));
  }

  /// Listen to a single invite document (by sessionId).
  static Stream<DocumentSnapshot> listenToInvite(String sessionId) {
    return _invitesRef.doc(sessionId).snapshots();
  }

  /// Stream all pending invites for a given recipient UID.
  static Stream<QuerySnapshot> streamPendingFor(String uid) {
    return _invitesRef
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Accept an invite. This will set status to 'accepted' and stamp accepted metadata.
  static Future<void> acceptInvite(
    String sessionId, {
    String? acceptedByUid,
  }) async {
    await _ensureAuth();
    final uid = acceptedByUid ?? _auth.currentUser?.uid;
    await _invitesRef.doc(sessionId).update({
      'status': 'accepted',
      'acceptedBy': uid,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject an invite.
  static Future<void> rejectInvite(
    String sessionId, {
    String? rejectedByUid,
  }) async {
    await _ensureAuth();
    final uid = rejectedByUid ?? _auth.currentUser?.uid;
    await _invitesRef.doc(sessionId).update({
      'status': 'rejected',
      'rejectedBy': uid,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
