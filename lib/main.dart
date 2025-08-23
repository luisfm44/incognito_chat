import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true; // ⚠️ Solo DEV
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Incognito Chat',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}