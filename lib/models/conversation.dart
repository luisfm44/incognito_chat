/// Representa una conversación entre participantes.
class Conversation {
  /// Identificador único de la conversación.
  final String id;

  /// Lista de identificadores de los participantes.
  final List<String> participants;

  Conversation({required this.id, this.participants = const []});

  /// Crea una instancia desde un mapa JSON.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversationId'] as String,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Convierte la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
    'conversationId': id,
    'participants': participants,
  };
}
