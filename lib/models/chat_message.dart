import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Representa un mensaje de chat entre usuarios.
@immutable
class ChatMessage extends Equatable {
  /// Identificador único del mensaje.
  final String messageId;

  /// ID de la conversación a la que pertenece el mensaje.
  final String conversationId;

  /// ID del usuario que envía el mensaje.
  final String fromUserId;

  /// Contenido textual del mensaje.
  final String content;

  /// Marca de tiempo generada por el cliente.
  final DateTime timestampClient;

  /// Marca de tiempo generada por el servidor (opcional).
  final DateTime? timestampServer;

  const ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.fromUserId,
    required this.content,
    required this.timestampClient,
    this.timestampServer,
  });

  /// Crea una instancia desde un mapa JSON.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      fromUserId: json['fromUserId'] as String,
      content: json['content'] as String,
      timestampClient: DateTime.parse(json['timestampClient'] as String),
      timestampServer: json['timestampServer'] != null
          ? DateTime.parse(json['timestampServer'] as String)
          : null,
    );
  }

  /// Convierte la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'conversationId': conversationId,
    'fromUserId': fromUserId,
    'content': content,
    'timestampClient': timestampClient.toIso8601String(),
    if (timestampServer != null)
      'timestampServer': timestampServer!.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    messageId,
    conversationId,
    fromUserId,
    content,
    timestampClient,
    timestampServer,
  ];
}