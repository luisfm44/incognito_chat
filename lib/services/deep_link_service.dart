// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import '../core/logger.dart';

class DeepLinkService {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _initialHandled = false;

  Future<void> init(void Function(Uri uri) onUri) async {
    _appLinks ??= AppLinks();

    if (!_initialHandled) {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        log.i('Deep link inicial recibido: $initialUri');
        onUri(initialUri);
      }
      _initialHandled = true;
    }

    await _sub?.cancel();
    _sub = _appLinks!.uriLinkStream.listen(
          (uri) {
        if (uri != null) {
          log.d('Deep link en caliente: $uri');
          onUri(uri);
        }
      },
      onError: (err, stack) {
        log.e('Error escuchando deep links', error: err, stackTrace: stack);
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    log.w('DeepLinkService detenido');
  }

  Future<void> dispose() async {
    await stop();
    _appLinks = null;
    _initialHandled = false;
    log.w('DeepLinkService liberado');
  }
}