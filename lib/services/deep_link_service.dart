import 'dart:async';
import 'package:app_links/app_links.dart';
import '../core/logger.dart';

/// Servicio para gestionar deep links en la app.
class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _initialHandled = false;

  /// Inicializa el servicio y comienza a escuchar deep links.
  Future<void> init(void Function(Uri uri) onUri) async {
    _appLinks = _appLinks ?? AppLinks();
    await _handleInitialLink(onUri);
    await _subscribeToLinks(onUri);
  }

  Future<void> _handleInitialLink(void Function(Uri uri) onUri) async {
    if (_initialHandled) return;
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      log.i('Deep link inicial recibido: $initialUri');
      onUri(initialUri);
    }
    _initialHandled = true;
  }

  Future<void> _subscribeToLinks(void Function(Uri uri) onUri) async {
    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
          (uri) {
        log.d('Deep link en caliente: $uri');
        onUri(uri);
      },
      onError: (err, stack) {
        log.e('Error escuchando deep links', error: err, stackTrace: stack);
      },
      cancelOnError: false,
    );
  }

  /// Detiene la escucha de deep links.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    log.w('DeepLinkService detenido');
  }

  /// Libera los recursos del servicio.
  Future<void> dispose() async {
    await stop();
    _initialHandled = false;
    log.w('DeepLinkService liberado');
  }

  /// Indica si el servicio está escuchando deep links.
  bool get isListening => _sub != null;
}