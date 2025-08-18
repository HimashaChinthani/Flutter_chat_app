import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/invite_service.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? uid;

  @override
  void initState() {
    super.initState();
    _ensureUid();
  }

  Future<void> _ensureUid() async {
    final auth = fb_auth.FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
    setState(() => uid = auth.currentUser?.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read),
            onPressed: () async {
              await NotificationService.markAllReadFor(uid!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All notifications marked as read')),
              );
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.streamNotificationsFor(uid!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When someone sends you a chat request,\nyou\'ll see it here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final fromName = (data['fromName'] as String?) ?? 'Someone';
              final message = (data['message'] as String?) ?? '';
              final title = (data['title'] as String?) ?? 'Notification';
              final read = (data['read'] as bool?) ?? false;
              final type = (data['type'] as String?) ?? '';
              final createdAt = data['createdAt'] as Timestamp?;

              // Format time
              String timeText = '';
              if (createdAt != null) {
                final now = DateTime.now();
                final notificationTime = createdAt.toDate();
                final difference = now.difference(notificationTime);

                if (difference.inDays > 0) {
                  timeText = '${difference.inDays}d ago';
                } else if (difference.inHours > 0) {
                  timeText = '${difference.inHours}h ago';
                } else if (difference.inMinutes > 0) {
                  timeText = '${difference.inMinutes}m ago';
                } else {
                  timeText = 'Just now';
                }
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: read ? 1 : 3,
                color: read ? Colors.grey[50] : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == 'chat_invite'
                        ? AppTheme.primaryPurple
                        : Colors.blue,
                    child: Icon(
                      type == 'chat_invite' ? Icons.chat : Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'From: $fromName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Spacer(),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: read
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () async {
                    // If it's a chat invite, show accept/reject dialog
                    final sessionId = (data['sessionId'] as String?);
                    if (type == 'chat_invite' && sessionId != null) {
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.chat, color: AppTheme.primaryPurple),
                              SizedBox(width: 8),
                              Text('Chat Request'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryPurple,
                                child: Text(
                                  fromName.isNotEmpty
                                      ? fromName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '$fromName wants to chat with you',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Would you like to accept or reject this invitation?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                              ),
                              child: Text('Accept'),
                            ),
                          ],
                        ),
                      );

                      if (accepted == true) {
                        await InviteService.acceptInvite(sessionId);
                        // open chat
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              sessionId: sessionId,
                              isHost: false,
                              peerName: fromName,
                            ),
                          ),
                        );
                        await NotificationService.markRead(doc.id);
                      } else if (accepted == false) {
                        await InviteService.rejectInvite(sessionId);
                        await NotificationService.markRead(doc.id);
                      }
                    } else {
                      // Just mark as read for other notification types
                      await NotificationService.markRead(doc.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
