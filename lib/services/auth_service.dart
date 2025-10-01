import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

/// Servicio de autenticación para gestionar usuario y token.
class AuthService {
  static const _kUserIdKey = 'userId';
  final ApiClient api;

  AuthService(this.api);

  /// Asegura que exista un userId y obtiene el token correspondiente.
  Future<(String userId, String token)> ensureIdentityAndToken() async {
    final userId = await _getOrCreateUserId();
    final token = await api.register(userId);
    return (userId, token);
  }

  /// Obtiene el userId almacenado o genera uno nuevo si no existe.
  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_kUserIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_kUserIdKey, userId);
    }
    return userId;
  }
}