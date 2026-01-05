import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/services/version_service.dart';

void main() {
  group('VersionService', () {
    test('should be a singleton', () {
      final instance1 = VersionService.instance;
      final instance2 = VersionService.instance;
      expect(instance1, equals(instance2));
    });

    test('should have a version string', () {
      final service = VersionService.instance;
      expect(service.version, isA<String>());
      expect(service.version.isNotEmpty, isTrue);
    });

    test('should have a build number', () {
      final service = VersionService.instance;
      expect(service.buildNumber, isA<String>());
    });

    test('should have all version properties', () {
      final service = VersionService.instance;
      expect(service.version, isA<String>());
      expect(service.buildNumber, isA<String>());
      expect(service.appName, isA<String>());
      expect(service.packageName, isA<String>());
      expect(service.fullVersion, isA<String>());
      expect(service.displayVersion, isA<String>());
      expect(service.versionInfo, isA<Map<String, String>>());
    });

    test('should format fullVersion correctly', () {
      final service = VersionService.instance;
      expect(service.fullVersion, contains(service.version));
      expect(service.fullVersion, contains(service.buildNumber));
    });

    test('should format displayVersion correctly', () {
      final service = VersionService.instance;
      expect(service.displayVersion, startsWith('v'));
      expect(service.displayVersion, contains(service.version));
    });

    test('should have versionInfo with all keys', () {
      final service = VersionService.instance;
      final info = service.versionInfo;
      expect(info.containsKey('version'), isTrue);
      expect(info.containsKey('buildNumber'), isTrue);
      expect(info.containsKey('appName'), isTrue);
      expect(info.containsKey('packageName'), isTrue);
      expect(info.containsKey('fullVersion'), isTrue);
      expect(info.containsKey('displayVersion'), isTrue);
    });
  });
}
