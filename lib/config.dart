// lib/config.dart
class AppConfig {
  static const host = '10.0.2.2';
  static const restBase = 'http://$host:8080'; // <-- TU puerto de Spring
  static const wsUrl   = 'wss://$host:5223/chat';
}