import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/env/env.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    dotenv.clean();
    debugDefaultTargetPlatformOverride = null;
  });

  test('apiBaseUrl appends api to root base url', () {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:5186');

    expect(Env.baseUrl, 'http://localhost:5186');
    expect(Env.apiBaseUrl, 'http://localhost:5186/api');
    expect(Env.notificationsHubUrl, 'http://localhost:5186/hubs/notifications');
  });

  test('apiBaseUrl avoids double slash when base url has trailing slash', () {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:5186/');

    expect(Env.apiBaseUrl, 'http://localhost:5186/api');
    expect(Env.notificationsHubUrl, 'http://localhost:5186/hubs/notifications');
  });
}
