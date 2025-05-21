import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/helpers/chat_service.dart';
import '../services/helpers/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ChatWidgetDrawer extends StatefulWidget {
  const ChatWidgetDrawer({super.key});

  @override
  State<ChatWidgetDrawer> createState() => _ChatWidgetDrawerState();
}

class _ChatWidgetDrawerState extends State<ChatWidgetDrawer> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  late final String _myUserId;
  List<Message> _previousMessages = [];

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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la foto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final drawerWidth = constraints.maxWidth < 600
              ? constraints.maxWidth * 0.98
              : 400;

          return SizedBox(
            width: drawerWidth.toDouble(),
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
                        onPressed: () => Navigator.pop(context),
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

                      if (_previousMessages.isNotEmpty &&
                          messages.length > _previousMessages.length) {
                        final newMessage = messages.last;
                        if (newMessage.userId != _myUserId) {
                          NotificationService.showNotification(
                            'Nuevo mensaje',
                            newMessage.content.length > 50
                                ? '${newMessage.content.substring(0, 50)}...'
                                : newMessage.content,
                          );
                        }
                      }
                      _previousMessages = List.from(messages);

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final currentMessage = messages[messages.length - 1 - index];
                          final isMe = currentMessage.userId == _myUserId;
                          final isImage = currentMessage.content.startsWith('http');

                          return GestureDetector(
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.push_pin),
                                      title: const Text('Anclar mensaje'),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Mensaje anclado (UI temporal).')),
                                        );
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.warning),
                                      title: const Text('Marcar como advertencia'),
                                      onTap: () {
                                        NotificationService.showNotification(
                                          'Mensaje de advertencia',
                                          currentMessage.content,
                                        );
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: drawerWidth * 0.8,
                                  minWidth: 60,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? chatColor : receivedColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      isImage
                                          ? Image.network(
                                              currentMessage.content,
                                              width: drawerWidth * 0.7,
                                              fit: BoxFit.contain,
                                            )
                                          : Text(
                                              currentMessage.content,
                                              style: TextStyle(
                                                color: isMe ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('HH:mm').format(
                                          currentMessage.createdAt is String
                                              ? DateTime.parse(currentMessage.createdAt as String)
                                              : currentMessage.createdAt,
                                        ),
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                            // ignore: deprecated_member_use
                            suffixIcon: Icon(Icons.emoji_emotions_outlined, color: chatColor.withOpacity(0.7)),
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
          );
        },
      ),
    );
  }
}
