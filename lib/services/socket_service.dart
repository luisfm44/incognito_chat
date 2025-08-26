// lib/services/socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, HttpOverrides, SecurityContext, X509Certificate; // IO only
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // IO: headers y mejor control

import '../models/ws_envelope.dart';
import '../models/chat_message.dart';

typedef AckCallback = void Function(String messageId);

enum SocketStatus { connecting, open, closed }

class SocketService {
  final String userId;
  /// Ej: wss://10.0.2.2:5223/chat   (IMPORTANTE: esquema wss://)
  final String wsBase;
  /// JWT o similar
  final String authToken;

  final void Function(ChatMessage) onMessage;
  final void Function(String messageId)? onAck;
  final void Function(dynamic error)? onError;
  final void Function()? onClosed;

  WebSocketChannel? _channel;
  SocketStatus status = SocketStatus.closed;

  Timer? _heartbeat;
  bool _manuallyClosed = false;
  Duration _backoff = const Duration(seconds: 2);

  SocketService({
    required this.userId,
    required this.wsBase,
    required this.authToken,
    required this.onMessage,
    this.onAck,
    this.onError,
    this.onClosed,
  });

  /// En Web no podemos mandar headers arbitrarios; usamos query param.
  Uri _uriForWeb() {
    final uri = Uri.parse(wsBase);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'auth': authToken, // Servidor debe aceptar este modo en Web.
    });
  }

  /// Conecta (no hace nada si ya está abriendo/abierta)
  void connect() {
    if (status == SocketStatus.connecting || status == SocketStatus.open) return;

    _manuallyClosed = false;
    status = SocketStatus.connecting;

    try {
      if (kIsWeb) {
        // Web: sin headers -> query param
        final uri = _uriForWeb();
        _channel = WebSocketChannel.connect(uri);
      } else {
        // IO: headers Authorization y permitir cert dev para hosts conocidos
        _installDevHttpOverrides();
        final uri = Uri.parse(wsBase);
        _channel = IOWebSocketChannel.connect(
          uri,
          headers: {
            'Authorization': 'Bearer $authToken',
            // Si tu servidor usa subprotocolo para auth:
            // 'Sec-WebSocket-Protocol': 'bearer, $authToken',
          },
        );
      }

      _listen();
    } catch (e) {
      onError?.call(e);
      _scheduleReconnect();
    }
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
              case 'pong':
              // opcional: manejar pongs
                break;
              default:
              // ignora otros tipos
                break;
            }
          }
        } catch (e) {
          onError?.call('WS parse error: $e');
        }
      },
      onDone: _onCloseAndMaybeReconnect,
      onError: (err) {
        onError?.call(err);
        // el stream se cerrará por cancelOnError=true
      },
      cancelOnError: true,
    );

    // Consideramos "open" al quedar suscrito sin error
    status = SocketStatus.open;
    _backoff = const Duration(seconds: 2);
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
    _manuallyClosed = true;
    _channel?.sink.close();
    status = SocketStatus.closed;
  }

  void _onCloseAndMaybeReconnect() {
    status = SocketStatus.closed;
    _heartbeat?.cancel();
    onClosed?.call();
    if (_manuallyClosed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (status != SocketStatus.closed) return;
    final wait = _backoff;
    _backoff = Duration(seconds: (_backoff.inSeconds * 2).clamp(2, 32));
    Future.delayed(wait, () {
      if (!_manuallyClosed && status == SocketStatus.closed) {
        connect();
      }
    });
  }

  /// DEV ONLY: permite cert self-signed para hosts locales (evita SslCloseCompletionEvent).
  void _installDevHttpOverrides() {
    // Ajusta los hosts/puertos de desarrollo que usas:
    final allowed = <String>{
      '10.0.2.2:5223',
      '127.0.0.1:5223',
      'localhost:5223',
    };
    HttpOverrides.global = _DevHttpOverrides(allowedHosts: allowed);
  }
}

class _DevHttpOverrides extends HttpOverrides {
  _DevHttpOverrides({required this.allowedHosts});
  final Set<String> allowedHosts;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // SOLO DEV: aceptar certs self-signed para estos hosts:puerto
      return allowedHosts.contains('$host:$port');
    };
    return client;
  }
}