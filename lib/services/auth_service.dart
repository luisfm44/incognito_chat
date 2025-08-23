import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';


class AuthService {
  static const _kUserIdKey = 'userId';
  final ApiClient api;


  AuthService(this.api);


  Future<(String userId, String token)> ensureIdentityAndToken() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_kUserIdKey);
    userId ??= const Uuid().v4();
    await prefs.setString(_kUserIdKey, userId);


    final token = await api.register(userId);
    return (userId, token);
  }
}