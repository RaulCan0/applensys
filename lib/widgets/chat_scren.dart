// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Para formatear fechas y horas

class ChatWidgetDrawer extends StatefulWidget {
  const ChatWidgetDrawer({super.key});

  @override
  State<ChatWidgetDrawer> createState() => _ChatWidgetDrawerState();
}

class _ChatWidgetDrawerState extends State<ChatWidgetDrawer> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  late final String _myUserId;

  final Color chatColor = Colors.teal;
  final Color receivedColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    _myUserId = session!.user.id;
  }

  Future<void> _tomarYSubirFoto() async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto != null) {
      final file = File(foto.path);
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}_$_myUserId.jpg';
      final storageResponse = await Supabase.instance.client.storage
          .from('chats')
          .upload(fileName, file);

      if (storageResponse.isNotEmpty) {
        final url = Supabase.instance.client.storage
            .from('chats')
            .getPublicUrl(fileName);
        await _chatService.sendMessage(_myUserId, url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la foto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: chatColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Cierra el Drawer
                    },
                  ),
                  const Text(
                    'Chat General',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _chatService.messageStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final currentMessage = messages[messages.length - 1 - index];
                      final isMe = currentMessage.userId == _myUserId;
                      final isImage = currentMessage.content.startsWith('http');

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? chatColor : receivedColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              isImage
                                  ? Image.network(currentMessage.content)
                                  : Text(
                                      currentMessage.content,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(DateTime.parse(currentMessage.createdAt as String)),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: chatColor),
                    onPressed: _tomarYSubirFoto,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          // ignore: deprecated_member_use
                          icon: Icon(Icons.emoji_emotions_outlined, color: chatColor.withOpacity(0.7)),
                          onPressed: () {},
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: chatColor),
                    onPressed: () async {
                      final text = _textController.text.trim();
                      if (text.isEmpty) return;
                      await _chatService.sendMessage(_myUserId, text);
                      _textController.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}