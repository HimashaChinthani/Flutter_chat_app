// database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';
import '../models/chat_session.dart';

class DatabaseService {
  static Database? _db;

  // Initialize the database
  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat.db');

    return await openDatabase(
      path,
      version: 2, // Increment version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            senderId TEXT,
            receiverId TEXT,
            text TEXT,
            timestamp TEXT,
            sessionId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE chat_sessions(
            id TEXT PRIMARY KEY,
            startTime TEXT,
            endTime TEXT,
            messageCount INTEGER,
            lastMessage TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE messages ADD COLUMN sessionId TEXT
          ''');
          await db.execute('''
            CREATE TABLE chat_sessions(
              id TEXT PRIMARY KEY,
              startTime TEXT,
              endTime TEXT,
              messageCount INTEGER,
              lastMessage TEXT
            )
          ''');
        }
      },
    );
  }

  // Get or open the database
  static Future<Database> getDatabase() async {
    _db ??= await _initDb();
    return _db!;
  }

  // Insert a new message with session ID
  static Future<void> insertMessage(Message message) async {
    final db = await getDatabase();
    await db.insert('messages', message.toMap());
  }

  // Create a new chat session
  static Future<void> createChatSession(ChatSession session) async {
    final db = await getDatabase();
    await db.insert(
      'chat_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update a chat session
  static Future<void> updateChatSession(ChatSession session) async {
    final db = await getDatabase();
    await db.update(
      'chat_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // Retrieve all chat sessions
  static Future<List<ChatSession>> getChatSessions() async {
    final db = await getDatabase();
    final result = await db.query('chat_sessions', orderBy: 'startTime DESC');
    return result.map((map) => ChatSession.fromMap(map)).toList();
  }

  // Retrieve messages by sessionId
  static Future<List<Message>> getMessagesBySession(String sessionId) async {
    final db = await getDatabase();
    final result = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  // Delete a chat session and its messages
  static Future<void> deleteChatSession(String sessionId) async {
    final db = await getDatabase();
    await db.delete('messages', where: 'sessionId = ?', whereArgs: [sessionId]);
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // Get message count for a specific session
  static Future<int> getMessageCount(String sessionId) async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE sessionId = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get the last message for a specific session
  static Future<Message?> getLastMessage(String sessionId) async {
    final db = await getDatabase();
    final result = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Message.fromMap(result.first);
  }

  // Update session statistics (message count and last message)
  static Future<void> updateSessionStats(String sessionId) async {
    final messageCount = await getMessageCount(sessionId);
    final lastMessage = await getLastMessage(sessionId);

    if (lastMessage != null) {
      final db = await getDatabase();
      await db.update(
        'chat_sessions',
        {'messageCount': messageCount, 'lastMessage': lastMessage.text},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  // End a chat session (set endTime)
  static Future<void> endChatSession(String sessionId) async {
    final db = await getDatabase();
    await db.update(
      'chat_sessions',
      {'endTime': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Check if a chat session exists
  static Future<bool> sessionExists(String sessionId) async {
    final db = await getDatabase();
    final result = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Get a specific chat session by ID
  static Future<ChatSession?> getChatSession(String sessionId) async {
    final db = await getDatabase();
    final result = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ChatSession.fromMap(result.first);
  }

  // Clear all data (useful for testing or reset functionality)
  static Future<void> clearAllData() async {
    final db = await getDatabase();
    await db.delete('messages');
    await db.delete('chat_sessions');
  }

  // Close database connection
  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
