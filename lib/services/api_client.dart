import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente REST de la app.
/// OJO: `baseUrl` debe apuntar al **REST** de Spring (p.ej. `http://10.0.2.2:8080`)
/// y NO al WebSocket (`wss://...:5223`).
class ApiClient {
  final String baseUrl;
  String? _authToken;
  final Duration timeout;

  ApiClient(this.baseUrl, {this.timeout = const Duration(seconds: 15)});

  String? get authToken => _authToken;
  set authToken(String? v) => _authToken = v;

  Map<String, String> _headersJson() => {
    'Content-Type': 'application/json',
    if (_authToken != null && _authToken!.isNotEmpty)
      'Authorization': 'Bearer $_authToken',
  };

  /// Registra el dispositivo/usuario y obtiene un token.
  /// Espera un body { "token": "<jwt>" }.
  Future<String> register(String userId) async {
    final uri = Uri.parse('$baseUrl/api/register');
    final res = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    )
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Registro falló: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (json['token'] ?? json['access_token']) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Registro ok pero sin token en la respuesta');
    }
    _authToken = token;
    return token;
  }

  /// Crea una conversación.
  /// Devuelve (conversationId, inviteToken).
  /// Acepta 2xx (200/201).
  Future<(String conversationId, String inviteToken)> createConversation() async {
    final uri = Uri.parse('$baseUrl/api/conversations');
    final res = await http.post(uri, headers: _headersJson()).timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Crear conversación falló: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final cid = json['conversationId'] as String?;
    final invite = json['inviteToken'] as String?;
    if (cid == null || invite == null) {
      throw Exception('Respuesta inválida al crear conversación: ${res.body}');
    }
    return (cid, invite);
  }

  /// Acepta una invitación.
  /// Enviamos el token por query para evitar malformaciones de body.
  /// Backend esperado: POST /api/invitations/accept?token=XYZ
  Future<String> acceptInvitation(String inviteToken) async {
    // Sanitiza: quita espacios/saltos de línea/emoji/etc
    final cleaned = inviteToken
        .trim()
        .replaceAll(RegExp(r'[^a-fA-F0-9-]'), ''); // solo hex y guiones

    // Logs temporales
    // ignore: avoid_print
    print('ACCEPT token="$cleaned" len=${cleaned.length}  base=$baseUrl');

    final uri = Uri.parse('$baseUrl/api/invitations/accept')
        .replace(queryParameters: {'token': cleaned});

    final res = await http.post(uri, headers: _headersJson()).timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Aceptar invitación falló: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final cid = json['conversationId'] as String?;
    if (cid == null) {
      throw Exception('Respuesta inválida al aceptar invitación: ${res.body}');
    }
    return cid;
  }
}