import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/realtime_chat_service.dart';
import 'chat_screen.dart';
import 'welcome_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  final bool showAppBar;
  final bool onlyUnread;
  final VoidCallback? onBackToHome;
  const ChatHistoryScreen({
    Key? key,
    this.showAppBar = true,
    this.onlyUnread = false,
    this.onBackToHome,
  }) : super(key: key);

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  bool _isConfirmingBack = false;

  Future<bool> _handleBackPressed() async {
    // Prevent multiple dialogs from stacking (system + UI back taps)
    if (_isConfirmingBack) return false;
    _isConfirmingBack = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Leave chat history?'),
          content: Text(
            'Do you want to leave Chat History and return to Welcome?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Leave'),
            ),
          ],
        );
      },
    );

    _isConfirmingBack = false;

    if (result == true) {
      // User chose to leave: navigate back to welcome (or call callback)
      if (widget.onBackToHome != null) {
        widget.onBackToHome!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      }
    }

    // Always intercept the original pop because we handled navigation manually
    return false;
  }

  @override
  void initState() {
    super.initState();
  }

  void deleteChatSession(String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Chat from Your History'),
          content: Text(
            'This will remove the chat session from your account. The other participant will keep the chat unless they also remove it. If no participants remain, the chat will be deleted permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await RealtimeChatService.deleteSession(sessionId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat removed from your history'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                leading: IconButton(
                  icon: const BackButtonIcon(),
                  color: Colors.white,
                  onPressed: () => _handleBackPressed(),
                ),
                title: Text('Chat History'),
                backgroundColor: AppTheme.primaryPurple,
              )
            : null,
        body: widget.onlyUnread
            ? StreamBuilder<QuerySnapshot>(
                stream:
                    RealtimeChatService.streamSessionsWithUnreadForCurrentUser(),
                builder: (context, msgSnap) {
                  if (msgSnap.hasError)
                    return Center(child: Text('Error loading unread chats'));
                  if (!msgSnap.hasData)
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPurple,
                      ),
                    );

                  // Build a map of sessionId -> latest message data for unread messages
                  final docs = msgSnap.data!.docs;
                  final Map<String, Map<String, dynamic>> latestBySession = {};
                  for (final d in docs) {
                    final data = d.data() as Map<String, dynamic>?;
                    if (data == null) continue;
                    final sid = (data['sessionId'] as String?) ?? '';
                    if (sid.isEmpty) continue;
                    final ts = (data['timestampMillis'] as int?) ?? 0;
                    final existing = latestBySession[sid];
                    if (existing == null ||
                        (existing['timestampMillis'] as int? ?? 0) < ts) {
                      latestBySession[sid] = {
                        'lastMessage': data['text'] ?? '',
                        'timestampMillis': ts,
                        'sessionId': sid,
                        'senderId': data['senderId'] ?? '',
                      };
                    }
                  }

                  if (latestBySession.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No unread messages',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Convert to list and sort by latest timestamp desc
                  final sessionsList = latestBySession.values.toList()
                    ..sort(
                      (a, b) => (b['timestampMillis'] as int).compareTo(
                        a['timestampMillis'] as int,
                      ),
                    );

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: sessionsList.length,
                    itemBuilder: (context, index) {
                      final data = sessionsList[index];
                      final sessionId = data['sessionId'] as String;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: RealtimeChatService.getSessionInfo(sessionId),
                          builder: (context, sessSnap) {
                            final sess = sessSnap.data;
                            final peerName = sess != null
                                ? (sess['peerName'] ?? 'Unknown Chat')
                                : 'Unknown Chat';
                            // isActive variable removed (no longer used)

                            return ListTile(
                              tileColor: Color(0xFFF3F1FF),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryPurple,
                                child: Icon(Icons.chat, color: Colors.white),
                              ),
                              title: Text(
                                peerName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['lastMessage'] ?? 'No messages',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  // Text(
                                  //   'Session: $sessionId',
                                  //   style: TextStyle(
                                  //     fontSize: 12,
                                  //     color: Colors.grey,
                                  //   ),
                                  // ),
                                ],
                              ),
                              trailing: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    // Active dot removed
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      sessionId: sessionId,
                                      isHost: sess != null
                                          ? (sess['createdBy'] ==
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid)
                                          : false,
                                      peerName: peerName,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () {
                                deleteChatSession(sessionId);
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_sessions')
                    .where(
                      'participants',
                      arrayContains: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading chat history'),
                          Text(snapshot.error.toString()),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPurple,
                      ),
                    );
                  }

                  final chatSessions = snapshot.data!.docs;

                  // Sort sessions by lastActivity on client side
                  chatSessions.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aActivity = aData['lastActivity'] as Timestamp?;
                    final bActivity = bData['lastActivity'] as Timestamp?;

                    if (aActivity != null && bActivity != null) {
                      return bActivity.compareTo(aActivity); // Descending order
                    }

                    final aCreated = aData['createdAt'] as Timestamp?;
                    final bCreated = bData['createdAt'] as Timestamp?;

                    if (aCreated != null && bCreated != null) {
                      return bCreated.compareTo(aCreated); // Descending order
                    }

                    return 0;
                  });

                  if (chatSessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No chat history',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start a new chat to see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: chatSessions.length,
                    itemBuilder: (context, index) {
                      final session = chatSessions[index];
                      final data = session.data() as Map<String, dynamic>;

                      return FutureBuilder<String>(
                        future: (() async {
                          final participants =
                              (data['participants'] as List?)?.cast<String>() ??
                              [];
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          String peerUid = '';
                          if (participants.length == 2 && currentUid != null) {
                            peerUid = participants.firstWhere(
                              (p) => p != currentUid,
                              orElse: () => '',
                            );
                          }
                          if (peerUid.isNotEmpty) {
                            try {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(peerUid)
                                  .get();
                              if (userDoc.exists) {
                                final userData = userDoc.data();
                                final name = userData?['name'];
                                if (name is String && name.isNotEmpty)
                                  return name;
                              }
                            } catch (_) {}
                          }
                          final fallback = data['peerName'];
                          if (fallback is String && fallback.isNotEmpty)
                            return fallback;
                          return 'Unknown Chat';
                        })(),
                        builder: (context, peerSnap) {
                          final peerName = peerSnap.data ?? 'Unknown Chat';
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: StreamBuilder<int>(
                              stream:
                                  RealtimeChatService.streamUnreadCountForSession(
                                    data['sessionId'] ?? '',
                                  ),
                              builder: (context, unreadSnap) {
                                final unread = unreadSnap.data ?? 0;
                                final hasUnread = unread > 0;
                                if (widget.onlyUnread && unread == 0)
                                  return SizedBox.shrink();

                                return ListTile(
                                  tileColor: hasUnread
                                      ? Color(0xFFF3F1FF)
                                      : Colors.transparent,
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryPurple,
                                    child: Icon(
                                      Icons.chat,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    peerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hasUnread ? Colors.black : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['lastMessage'] ?? 'No messages',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      // Text(
                                      //   'Session: ${data['sessionId']}',
                                      //   style: TextStyle(
                                      //     fontSize: 12,
                                      //     color: Colors.grey,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  trailing: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (hasUnread)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryPurple,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              unread > 99 ? '99+' : '$unread',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        // Removed Active/Ended text and green/red dot
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          sessionId: data['sessionId'],
                                          isHost:
                                              data['createdBy'] ==
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid,
                                          peerName: peerName,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    deleteChatSession(data['sessionId']);
                                  },
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
