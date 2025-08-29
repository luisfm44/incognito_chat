import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Instancia global para usar en toda la app: `log.d(...)`, `log.e(...)`, etc.
late final Logger log;

/// Inicializa el logger y engancha los errores globales de Flutter/Zones.
/// Llama a esto lo antes posible (p. ej., en main()).
Future<void> initLogger({required bool isRelease}) async {
  // Printer distinto para debug vs release
  final printer = isRelease
      ? PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: false,
    printEmojis: false,
    printTime: true,
  )
      : PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    printTime: true,
  );

  log = Logger(
    level: isRelease ? Level.info : Level.debug,
    printer: printer,
    // Puedes agregar sinks/salidas personalizadas con outputs: [...]
  );

  // Captura errores de Flutter (UI)
  FlutterError.onError = (FlutterErrorDetails details) {
    // Muestra en consola de Flutter
    FlutterError.presentError(details);
    // Registra con logger
    log.e('FlutterError', error: details.exception, stackTrace: details.stack);
  };
}

/// Helper para usar runZonedGuarded desde main y capturar todo.
Future<void> runWithZonedLogging(Future<void> Function() body) async {
  return runZonedGuarded(
    body,
        (error, stack) => log.e('Uncaught zone error', error: error, stackTrace: stack),
  );
}