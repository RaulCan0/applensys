class Message {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
