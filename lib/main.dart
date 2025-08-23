import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const IncognitoChatApp());
}

class IncognitoChatApp extends StatelessWidget {
  const IncognitoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Incognito Chat',
      home: ChatScreen(),
    );
  }
}