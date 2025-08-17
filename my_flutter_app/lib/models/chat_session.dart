class ChatSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int messageCount;
  final String lastMessage;
  final String? peerId;
  final String? peerName;

  ChatSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.messageCount,
    required this.lastMessage,
    this.peerId,
    this.peerName,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'messageCount': messageCount,
      'lastMessage': lastMessage,
      'peerId': peerId,
      'peerName': peerName,
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
      peerId: map.containsKey('peerId') ? map['peerId'] as String? : null,
      peerName: map.containsKey('peerName') ? map['peerName'] as String? : null,
    );
  }

  // Copy with method for updating session data
  ChatSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? messageCount,
    String? lastMessage,
    String? peerId,
    String? peerName,
  }) {
    return ChatSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
    );
  }
}
