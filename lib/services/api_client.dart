import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiClient {
  final String baseUrl; // p.ej. https://10.0.2.2:5223
  String? _authToken;


  ApiClient(this.baseUrl);


  String? get authToken => _authToken;
  set authToken(String? v) => _authToken = v;


  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };


  Future<String> register(String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode != 200) {
      throw Exception('Registro falló: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    _authToken = json['token'] as String;
    return _authToken!;
  }


  Future<(String conversationId, String inviteToken)> createConversation() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/conversations'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Crear conversación falló: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (
    json['conversationId'] as String,
    json['inviteToken'] as String,
    );
  }


  Future<String> acceptInvitation(String inviteToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/invitations/accept'),
      headers: _headers(),
      body: jsonEncode({'inviteToken': inviteToken}),
    );
    if (res.statusCode != 200) {
      throw Exception('Aceptar invitación falló: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['conversationId'] as String;
  }
}