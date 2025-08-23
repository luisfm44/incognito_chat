class WsEnvelope {
  final String type; // register|message|ack|presence|error
  final Map<String, dynamic> payload;


  WsEnvelope({required this.type, required this.payload});


  factory WsEnvelope.fromJson(Map<String, dynamic> json) {
    return WsEnvelope(
      type: json['type'] as String,
      payload: (json['payload'] ?? {}) as Map<String, dynamic>,
    );
  }


  Map<String, dynamic> toJson() => {
    'type': type,
    'payload': payload,
  };
}