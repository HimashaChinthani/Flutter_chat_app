import 'package:flutter/material.dart';
import '../theme.dart';

class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;

  const ChatScreen({
    Key? key,
    required this.sessionId,
    required this.isHost,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Message> messages = [];
  bool isConnected = true;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    // Simulate connection establishment
    Future.delayed(Duration(seconds: 1), () {
      if (widget.isHost) {
        addMessage('Someone joined your chat session!', false);
      } else {
        addMessage('Connected to chat session', false);
        addMessage('Hello! I scanned your QR code.', true);
        // Simulate host response
        Future.delayed(Duration(seconds: 2), () {
          addMessage('Great! Welcome to our chat session.', false);
        });
      }
    });
  }

  void addMessage(String text, bool isMe) {
    setState(() {
      messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isMe: isMe,
        timestamp: DateTime.now(),
      ));
    });
    scrollToBottom();
  }

  void sendMessage() {
    if (messageController.text.trim().isNotEmpty) {
      final messageText = messageController.text.trim();
      addMessage(messageText, true);
      messageController.clear();
      
      // Show typing indicator
      setState(() {
        isTyping = true;
      });
      
      // Simulate receiving a response
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          isTyping = false;
        });
        if (mounted) {
          // Generate a simple response
          List<String> responses = [
            'Thanks for your message!',
            'That\'s interesting!',
            'I agree with you.',
            'Tell me more about that.',
            'Nice to hear from you!',
          ];
          final randomResponse = responses[DateTime.now().millisecond % responses.length];
          addMessage(randomResponse, false);
        }
      });
    }
  }

  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.exit_to_app, color: AppTheme.primaryPurple),
              SizedBox(width: 8),
              Text('End Chat Session'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to save this chat to history?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saving will allow you to view this conversation later in Chat History.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This will end the current chat session.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                exitWithoutSaving();
              },
              child: Text(
                'Exit without saving',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                saveAndExit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: Text('Save & Exit'),
            ),
          ],
        );
      },
    );
  }

  void saveAndExit() {
    // Here you would save to SQLite database
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Chat saved to history successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Navigate back to welcome screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void exitWithoutSaving() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Chat session ended without saving'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Session'),
            Text(
              widget.sessionId,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryPurple,
        actions: [
          IconButton(
            onPressed: showExitDialog,
            icon: Icon(Icons.exit_to_app),
            tooltip: 'End Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8),
            color: isConnected ? Colors.green : Colors.red,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return TypingIndicator();
                }
                final message = messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          
          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          messageController.clear();
                        },
                        icon: Icon(Icons.clear, size: 20),
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: sendMessage,
                  backgroundColor: AppTheme.primaryPurple,
                  mini: true,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMe ? AppTheme.primaryPurple : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(message.isMe ? 18 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Typing',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Text(
                  '...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
