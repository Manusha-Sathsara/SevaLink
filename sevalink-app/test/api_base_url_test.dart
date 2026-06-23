import 'package:flutter_test/flutter_test.dart';
import 'package:sevalink_app/main.dart';

void main() {
  group('resolveApiBaseUrl', () {
    test('uses localhost for web', () {
      expect(
        resolveApiBaseUrl(isWeb: true, isAndroid: false, isIOS: false),
        'http://localhost:8080/api/test-users',
      );
    });

    test('uses 10.0.2.2 for Android emulator', () {
      expect(
        resolveApiBaseUrl(isWeb: false, isAndroid: true, isIOS: false),
        'http://10.0.2.2:8080/api/test-users',
      );
    });

    test('uses localhost for iOS simulator', () {
      expect(
        resolveApiBaseUrl(isWeb: false, isAndroid: false, isIOS: true),
        'http://localhost:8080/api/test-users',
      );
    });

    test('falls back to localhost for desktop and other platforms', () {
      expect(
        resolveApiBaseUrl(isWeb: false, isAndroid: false, isIOS: false),
        'http://127.0.0.1:8080/api/test-users',
      );
    });
  });
}
