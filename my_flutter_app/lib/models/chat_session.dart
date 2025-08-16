class ChatSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int messageCount;
  final String lastMessage;

  ChatSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.messageCount,
    required this.lastMessage,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'messageCount': messageCount,
      'lastMessage': lastMessage,
    };
  }

  // Convert from Map
  static ChatSession fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      messageCount: map['messageCount'],
      lastMessage: map['lastMessage'],
    );
  }

  // Copy with method for updating session data
  ChatSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? messageCount,
    String? lastMessage,
  }) {
    return ChatSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
