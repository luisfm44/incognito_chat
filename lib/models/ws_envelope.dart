/// Representa un mensaje intercambiado por WebSocket.
class WsEnvelope {
  /// Tipo de mensaje: register, message, ack, presence, error, etc.
  final String type;

  /// Contenido del mensaje.
  final Map<String, dynamic>? payload;

  WsEnvelope({required this.type, this.payload});

  factory WsEnvelope.fromJson(Map<String, dynamic> json) {
    return WsEnvelope(
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'payload': payload,
  };
}