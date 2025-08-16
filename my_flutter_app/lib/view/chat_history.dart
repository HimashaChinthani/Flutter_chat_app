import 'package:flutter/material.dart';
import '../theme.dart';
import '../main.dart';
import 'chat_screen.dart';

class ChatSession {
  final String id;
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final int messageCount;
  final String lastMessage;

  ChatSession({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.messageCount,
    required this.lastMessage,
  });
}

class ChatHistoryScreen extends StatefulWidget {
  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatSession> chatSessions = [];

  @override
  void initState() {
    super.initState();
    loadChatHistory();
  }

  void loadChatHistory() {
    // Simulate loading chat history from SQLite
    setState(() {
      chatSessions = [
        ChatSession(
          id: '1',
          sessionId: 'chat_123456',
          startTime: DateTime.now().subtract(Duration(days: 1)),
          endTime: DateTime.now().subtract(Duration(days: 1, hours: -2)),
          messageCount: 25,
          lastMessage: 'Thanks for the great conversation!',
        ),
        ChatSession(
          id: '2',
          sessionId: 'chat_789012',
          startTime: DateTime.now().subtract(Duration(days: 3)),
          endTime: DateTime.now().subtract(Duration(days: 3, hours: -1)),
          messageCount: 12,
          lastMessage: 'See you later!',
        ),
        ChatSession(
          id: '3',
          sessionId: 'chat_345678',
          startTime: DateTime.now().subtract(Duration(days: 7)),
          endTime: DateTime.now().subtract(Duration(days: 7, hours: -3)),
          messageCount: 45,
          lastMessage: 'It was nice meeting you.',
        ),
      ];
    });
  }

  void deleteChatSession(String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Chat'),
          content: Text('Are you sure you want to delete this chat session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  chatSessions.removeWhere((session) => session.id == sessionId);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chat session deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void viewChatSession(ChatSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          sessionId: session.sessionId,
          isHost: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
        backgroundColor: AppTheme.primaryPurple,
        actions: [
          IconButton(
            onPressed: loadChatHistory,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: chatSessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chat history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation to see it here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: chatSessions.length,
              itemBuilder: (context, index) {
                final session = chatSessions[index];
                return ChatHistoryCard(
                  session: session,
                  onTap: () => viewChatSession(session),
                  onDelete: () => deleteChatSession(session.id),
                );
              },
            ),
    );
  }
}

class ChatHistoryCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatHistoryCard({
    Key? key,
    required this.session,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple,
          child: Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
        title: Text(
          session.sessionId,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              session.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.message, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  '${session.messageCount} messages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
