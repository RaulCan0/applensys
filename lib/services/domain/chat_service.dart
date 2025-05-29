import 'package:applensys/models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final _client = Supabase.instance.client;

  Future<void> sendMessage(String userId, String content) async {
    await _client.from('messages').insert({
      'id': const Uuid().v4(),
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Message>> messageStream() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => Message.fromMap(e)).toList());
  }
}