import '../models/message.dart';
import '../models/chat_session.dart';
import 'database_service.dart';

class ChatService {
  // Start a new chat session
  static Future<ChatSession> startNewChatSession(String sessionId) async {
    final session = ChatSession(
      id: sessionId,
      startTime: DateTime.now(),
      messageCount: 0,
      lastMessage: '',
    );

    await DatabaseService.createChatSession(session);
    return session;
  }

  // Send a message and update session
  static Future<void> sendMessage({
    required String sessionId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    // Create and save the message
    final message = Message(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      sessionId: sessionId,
    );

    await DatabaseService.insertMessage(message);

    // Update session statistics
    await DatabaseService.updateSessionStats(sessionId);
  }

  // Load or create a chat session
  static Future<ChatSession> getOrCreateSession(String sessionId) async {
    final existingSession = await DatabaseService.getChatSession(sessionId);

    if (existingSession != null) {
      return existingSession;
    } else {
      return await startNewChatSession(sessionId);
    }
  }

  // Get chat history with messages
  static Future<List<ChatSession>> getChatHistory() async {
    return await DatabaseService.getChatSessions();
  }

  // Get all messages for a chat session
  static Future<List<Message>> getChatMessages(String sessionId) async {
    return await DatabaseService.getMessagesBySession(sessionId);
  }

  // End a chat session
  static Future<void> endChat(String sessionId) async {
    await DatabaseService.endChatSession(sessionId);
    await DatabaseService.updateSessionStats(sessionId);
  }

  // Delete a chat session and all its messages
  static Future<void> deleteChat(String sessionId) async {
    await DatabaseService.deleteChatSession(sessionId);
  }

  // Generate a unique session ID
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'chat_$random';
  }

  // Check if user has any chat history
  static Future<bool> hasAnyChats() async {
    final sessions = await DatabaseService.getChatSessions();
    return sessions.isNotEmpty;
  }

  // Get recent chat sessions (last 10)
  static Future<List<ChatSession>> getRecentChats({int limit = 10}) async {
    final allSessions = await DatabaseService.getChatSessions();
    return allSessions.take(limit).toList();
  }
}
