class ChatMessage {
  final String messageId;
  final String conversationId;
  final String fromUserId;
  final String content;
  final DateTime timestampClient;
  final DateTime? timestampServer;


  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.fromUserId,
    required this.content,
    required this.timestampClient,
    this.timestampServer,
  });


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


  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'conversationId': conversationId,
    'fromUserId': fromUserId,
    'content': content,
    'timestampClient': timestampClient.toIso8601String(),
    if (timestampServer != null)
      'timestampServer': timestampServer!.toIso8601String(),
  };
}