class ChatMessage {
  final String from;
  final String to;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      from: json['from'],
      to: json['to'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}