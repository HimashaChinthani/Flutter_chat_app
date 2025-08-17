class User {
  final String id;
  final String name;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.createdAt});

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Convert from Map
  static User fromMap(Map<String, dynamic> map) {
    DateTime created;
    final raw = map['createdAt'];
    if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      created = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return User(id: map['id'], name: map['name'], createdAt: created);
  }
}
