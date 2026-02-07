import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/services/update_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateCheckService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should be a singleton', () {
      final instance1 = UpdateCheckService.instance;
      final instance2 = UpdateCheckService.instance;
      expect(instance1, equals(instance2));
    });

    test('clearLastCheck should remove cache keys', () async {
      final service = UpdateCheckService.instance;
      final prefs = await SharedPreferences.getInstance();

      // Set some test data
      await prefs.setString('last_update_check', '2024-01-01T00:00:00.000Z');
      await prefs.setString('last_check_version', '1.0.0');

      // Clear the cache
      await service.clearLastCheck();

      // Verify keys are removed
      expect(prefs.getString('last_update_check'), isNull);
      expect(prefs.getString('last_check_version'), isNull);
    });

    test('UpdateCheckResult should have all required fields', () {
      final result = UpdateCheckResult(
        updateRequired: true,
        forceUpdate: false,
        minVersion: '2.0.0',
        currentVersion: '1.0.0',
      );

      expect(result.updateRequired, isTrue);
      expect(result.forceUpdate, isFalse);
      expect(result.minVersion, equals('2.0.0'));
      expect(result.currentVersion, equals('1.0.0'));
    });

    // Note: checkForUpdate() requires actual HTTP calls and is better suited
    // for integration tests. Unit tests would require mocking HTTP and SharedPreferences.
  });
}
