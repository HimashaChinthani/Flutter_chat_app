// message.dart
class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String sessionId;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
      sessionId: map['sessionId'],
    );
  }
}
