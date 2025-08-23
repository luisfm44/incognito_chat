// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:uni_links/uni_links.dart';

class DeepLinkService {
  StreamSubscription<Uri?>? _sub;

  void listen(void Function(Uri uri) onUri) {
    _sub?.cancel();
    _sub = uriLinkStream.listen((uri) {
      if (uri != null) onUri(uri);
    }, onError: (err) {
      // log / manejo de error
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}