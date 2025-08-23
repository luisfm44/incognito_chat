import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';

class SocketService {
  final String myId;
  final WebSocketChannel channel;
  final void Function(ChatMessage) onMessageReceived;
  final void Function()? onConnectionClosed;
  final void Function(dynamic error)? onConnectionError;

  SocketService({
    required this.myId,
    required this.channel,
    required this.onMessageReceived,
    this.onConnectionClosed,
    this.onConnectionError,
  }) {
    print("🔌 Inicializando SocketService con UUID: $myId");
    _listen();
    _register();
  }

  void _listen() {
    print("👂 Escuchando canal de WebSocket...");
    channel.stream.listen(
          (data) {
        try {
          print("📦 Datos crudos recibidos: $data");
          final json = jsonDecode(data);
          final message = ChatMessage.fromJson(json);
          print("📥 Mensaje recibido: ${message.content} de ${message.from}");
          onMessageReceived(message);
        } catch (e) {
          print('❌ Error parsing message: $e');
        }
      },
      onDone: () {
        print("🔌 Conexión cerrada por el servidor.");
        onConnectionClosed?.call();
      },
      onError: (err) {
        print("⚠️ Error en la conexión: $err");
        onConnectionError?.call(err);
      },
      cancelOnError: true,
    );
  }

  void _register() async {
    print("🕓 Esperando para registrar usuario...");
    await Future.delayed(const Duration(milliseconds: 300));
    final registerMessage = ChatMessage(
      from: myId,
      to: '',
      content: '__register__',
      timestamp: DateTime.now(),
    );
    print("📝 Enviando mensaje de registro al servidor...");
    sendRaw(registerMessage);
  }

  void sendMessage({required String to, required String content}) {
    if (channel.closeCode != null) {
      print('❌ No se puede enviar, el canal no está listo.');
      return;
    }

    final message = ChatMessage(
      from: myId,
      to: to,
      content: content,
      timestamp: DateTime.now(),
    );
    sendRaw(message);
  }

  void sendRaw(ChatMessage message) {
    final json = jsonEncode(message.toJson());
    print("📤 Enviando mensaje: ${message.content} a ${message.to}");
    channel.sink.add(json);
  }

  void dispose() {
    print("🔒 Cerrando conexión de socket");
    channel.sink.close();
  }
}