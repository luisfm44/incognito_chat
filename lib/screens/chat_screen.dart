import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/chat_message.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/deep_link_service.dart';
import '../config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _inviteTokenController = TextEditingController();
  final DeepLinkService _links = DeepLinkService();

  late final ApiClient api;
  AuthService? auth;
  SocketService? socket;

  String? userId;
  String? authToken;
  String? conversationId;
  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    // REST va al puerto HTTP (AppConfig.restBase)
    api = ApiClient(AppConfig.restBase);
    auth = AuthService(api);
    _bootstrap();

    // Deep links: incognitochat://invite?token=XYZ
    _links.init((uri) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _inviteTokenController.text = token;
        _acceptInvite();
      }
    });
  }

  @override
  void dispose() {
    _links.dispose();
    socket?.dispose();
    _messageController.dispose();
    _inviteTokenController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final (uid, token) = await auth!.ensureIdentityAndToken();
      // 👉 Asigna el token al ApiClient para que envíe Authorization: Bearer ...
      api.authToken = token;

      setState(() {
        userId = uid;
        authToken = token;
      });

      _openSocket();
    } catch (e) {
      _snack('Error de registro: $e');
    }
  }

  void _openSocket() {
    if (userId == null || authToken == null) return;
    final wsUrl = AppConfig.wsUrl; // WSS en 5223
    socket = SocketService(
      userId: userId!,
      wsBase: wsUrl,
      authToken: authToken!,
      onMessage: (msg) => setState(() => messages.add(msg)),
      onAck: (_) {},
      onError: (err) => _snack('WS error: $err'),
      onClosed: () => _snack('Conexión cerrada, reintentando…'),
    )..connect();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createConversation() async {
    try {
      if (api.authToken == null) {
        _snack('Registrando dispositivo… intenta de nuevo en un momento');
        return;
      }
      final (cid, invite) = await api.createConversation();
      setState(() => conversationId = cid);
      final deepLink = 'incognitochat://invite?token=$invite';
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Invita a tu contacto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              QrImageView(data: deepLink, size: 180),
              const SizedBox(height: 12),
              SelectableText(deepLink, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Share.share(deepLink),
                icon: const Icon(Icons.share),
                label: const Text('Compartir enlace'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _snack('No se pudo crear la conversación: $e');
    }
  }

  Future<void> _acceptInvite() async {
    final token = _inviteTokenController.text.trim();
    if (token.isEmpty) return;
    try {
      final cid = await api.acceptInvitation(token);
      setState(() => conversationId = cid);
      _snack('¡Te uniste a la conversación!');
    } catch (e) {
      _snack('Invitación inválida: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || conversationId == null || userId == null) return;
    final msg = ChatMessage(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: conversationId!,
      fromUserId: userId!,
      content: text,
      timestampClient: DateTime.now(),
    );
    socket?.sendMessage(msg);
    setState(() {
      messages.add(msg);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = authToken != null; // deshabilitar "+" hasta tener token

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incognito Chat (v2)'),
        actions: [
          IconButton(
            tooltip: canCreate ? 'Nueva conversación' : 'Registrando…',
            onPressed: canCreate ? _createConversation : null,
            icon: const Icon(Icons.add_comment_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (userId != null)
            Container(
              color: Colors.indigo.withOpacity(0.05),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Mi userId: $userId', style: const TextStyle(fontSize: 12)),
                      ),
                      if (conversationId != null)
                        Text('Conv: $conversationId', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inviteTokenController,
                          decoration: const InputDecoration(
                            labelText: 'Pegar token de invitación',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _acceptInvite,
                        child: const Text('Unirme'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isMe = m.fromUserId == userId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.indigo[100] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.content),
                        const SizedBox(height: 4),
                        Text(
                          m.timestampServer?.toLocal().toString() ??
                              m.timestampClient.toLocal().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: conversationId == null
                            ? 'Crea o únete a una conversación…'
                            : 'Escribe un mensaje…',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      enabled: conversationId != null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: conversationId != null ? _sendMessage : null,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}