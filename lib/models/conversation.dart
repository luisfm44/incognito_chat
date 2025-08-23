class Conversation {
  final String id;
  final List<String> participants;


  Conversation({required this.id, this.participants = const []});


  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversationId'] as String,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}