import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart';

import '../models/chat_message.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _receiverIdController = TextEditingController();
  final _uuid = const Uuid();
  late final String myId;
  late final SocketService socketService;

  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    myId = _uuid.v4();

    final socket = IOWebSocketChannel.connect(
      Uri.parse('wss://10.0.2.2:5223/chat'),
    );


    socketService = SocketService(
      myId: myId,
      channel: socket,
      onMessageReceived: (ChatMessage message) {
        setState(() {
          messages.add(message);
        });
      },
      onConnectionClosed: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔌 Conexión cerrada con el servidor')),
            );
          }
        });
      },
      onConnectionError: (error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('⚠️ Error de conexión: $error')),
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    socketService.dispose();
    _messageController.dispose();
    _receiverIdController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    final receiverId = _receiverIdController.text.trim();
    if (text.isEmpty || receiverId.isEmpty) return;
    socketService.sendMessage(to: receiverId, content: text);
    setState(() {
      messages.add(ChatMessage(
        from: myId,
        to: receiverId,
        content: text,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Incognito Chat'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.indigo[50],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mi UUID: $myId',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copiar UUID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: myId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📋 UUID copiado al portapapeles')),
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _receiverIdController,
                  decoration: InputDecoration(
                    labelText: 'UUID del receptor',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.from == myId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.indigo[100] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                      ),
                      child: Text(
                        msg.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.indigo,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}