import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl => _normalizeBaseUrl(dotenv.env['BASE_URL'] ?? '');

  static String get apiBaseUrl => _appendPath(baseUrl, 'api');

  static String get notificationsHubUrl =>
      _appendPath(baseUrl, 'hubs/notifications');

  static String _normalizeBaseUrl(String rawBaseUrl) {
    if (rawBaseUrl.isEmpty) return rawBaseUrl;

    final uri = Uri.tryParse(rawBaseUrl);
    if (uri == null || !uri.hasAuthority) return rawBaseUrl;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return rawBaseUrl;
  }

  static String _appendPath(String root, String path) {
    if (root.isEmpty) return root;

    final cleanRoot = root.endsWith('/')
        ? root.substring(0, root.length - 1)
        : root;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return '$cleanRoot/$cleanPath';
  }
}
