import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_envelope.dart';
import '../models/chat_message.dart';

typedef AckCallback = void Function(String messageId);

enum SocketStatus { connecting, open, closed }
class SocketService {
  final String userId;
  final String wsBase; // ej: wss://10.0.2.2:5223/chat
  final String authToken; // JWT
  final void Function(ChatMessage) onMessage;
  final void Function(String messageId)? onAck;
  final void Function(dynamic error)? onError;
  final void Function()? onClosed;

  WebSocketChannel? _channel;
  SocketStatus status = SocketStatus.closed;
  Timer? _heartbeat;

  SocketService({
    required this.userId,
    required this.wsBase,
    required this.authToken,
    required this.onMessage,
    this.onAck,
    this.onError,
    this.onClosed,
  });

  Uri _uriWithAuth() {
    final uri = Uri.parse(wsBase);
// auth por query param (alternativamente usar headers)
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'auth': authToken,
    });
  }

  void connect() {
    status = SocketStatus.connecting;
    final uri = _uriWithAuth();
    _channel = WebSocketChannel.connect(uri);
    _listen();
  }

  void _listen() {
    _channel?.stream.listen(
          (raw) {
        try {
          final data = raw is String ? jsonDecode(raw) : raw;
          if (data is Map<String, dynamic> && data.containsKey('type')) {
            final env = WsEnvelope.fromJson(data);
            switch (env.type) {
              case 'message':
                onMessage(ChatMessage.fromJson(env.payload));
                break;
              case 'ack':
                final id = (env.payload['messageId'] ?? '').toString();
                if (id.isNotEmpty) onAck?.call(id);
                break;
              case 'error':
                onError?.call(env.payload);
                break;
            }
          }
        } catch (e) {
          onError?.call('WS parse error: $e');
        }
      },
      onDone: () {
        status = SocketStatus.closed;
        _heartbeat?.cancel();
        onClosed?.call();
// Reintento simple
        Future.delayed(const Duration(seconds: 2), () {
          if (status == SocketStatus.closed) connect();
        });
      },
      onError: (err) {
        onError?.call(err);
      },
      cancelOnError: true,
    );


    status = SocketStatus.open;
    _startHeartbeat();
    _sendRegister();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _send(WsEnvelope(type: 'ping', payload: {'t': DateTime.now().toIso8601String()}));
    });
  }


  void _sendRegister() {
    _send(WsEnvelope(type: 'register', payload: {
      'userId': userId,
    }));
  }


  void sendMessage(ChatMessage msg) {
    _send(WsEnvelope(type: 'message', payload: msg.toJson()));
  }


  void _send(WsEnvelope env) {
    final jsonStr = jsonEncode(env.toJson());
    _channel?.sink.add(jsonStr);
  }


  void dispose() {
    _heartbeat?.cancel();
    _channel?.sink.close();
  }
}