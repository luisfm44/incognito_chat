// lib/services/socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, X509Certificate; // IO only
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../models/ws_envelope.dart';
import '../models/chat_message.dart';

typedef AckCallback = void Function(String messageId);

enum SocketStatus { connecting, open, closed }

class SocketService {
  final String userId;
  /// Ej: wss://10.0.2.2:5223/chat
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

  /// Conecta el WebSocket si no está abierto.
  void connect() {
    if (_isConnectingOrOpen()) return;
    _manuallyClosed = false;
    status = SocketStatus.connecting;

    try {
      _channel = _createChannel();
      _listen();
    } catch (e) {
      onError?.call(e);
      _scheduleReconnect();
    }
  }

  WebSocketChannel _createChannel() {
    if (kIsWeb) {
      return WebSocketChannel.connect(_uriForWeb());
    } else {
      final client = _createHttpClient();
      return IOWebSocketChannel.connect(
        Uri.parse(wsBase),
        headers: {'Authorization': 'Bearer $authToken'},
        customClient: client,
        pingInterval: const Duration(seconds: 20),
      );
    }
  }

  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      if (!kDebugMode) return false;
      final hp = '$host:$port';
      return hp == '10.0.2.2:5223' || hp == 'localhost:5223' || hp == '127.0.0.1:5223';
    };
    return client;
  }

  bool _isConnectingOrOpen() =>
      status == SocketStatus.connecting || status == SocketStatus.open;

  void _listen() {
    _channel?.stream.listen(
      _handleRawMessage,
      onDone: _onCloseAndMaybeReconnect,
      onError: onError,
      cancelOnError: true,
    );
    status = SocketStatus.open;
    _backoff = const Duration(seconds: 2);
    _startHeartbeat();
    _sendRegister();
  }

  void _handleRawMessage(dynamic raw) {
    try {
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is Map<String, dynamic> && data.containsKey('type')) {
        _handleEnvelope(WsEnvelope.fromJson(data));
      }
    } catch (e) {
      onError?.call('WS parse error: $e');
    }
  }

  void _handleEnvelope(WsEnvelope env) {
    switch (env.type) {
      case 'message':
        final payload = env.payload;
        if (payload != null) onMessage(ChatMessage.fromJson(payload));
        break;
      case 'ack':
        final payload = env.payload;
        final id = (payload != null ? payload['messageId'] : '')?.toString() ?? '';
        if (id.isNotEmpty) onAck?.call(id);
        break;
      case 'error':
        onError?.call(env.payload);
        break;
      case 'pong':
        break;
      default:
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _send(WsEnvelope(type: 'ping', payload: {'t': DateTime.now().toIso8601String()}));
    });
  }

  void _sendRegister() {
    _send(WsEnvelope(type: 'register', payload: {'userId': userId}));
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

  Uri _uriForWeb() {
    final uri = Uri.parse(wsBase);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'auth': authToken,
    });
  }
}