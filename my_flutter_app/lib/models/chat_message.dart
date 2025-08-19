class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final String sessionId;
  final bool isMe;
  final bool read;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.sessionId,
    required this.isMe,
    required this.read,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'read': read,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String currentUserId,
  ) {
    return ChatMessage(
      id: id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      timestamp: DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      sessionId: data['sessionId'] ?? '',
      isMe: data['senderId'] == currentUserId,
      read: (data['read'] as bool?) ?? false,
    );
  }
}
