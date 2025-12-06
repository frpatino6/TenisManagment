import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tennis_management/core/services/tenant_service.dart';

void main() {
  group('TenantService', () {
    late TenantService tenantService;
    late SharedPreferences prefs;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      tenantService = TenantService();
    });

    test('should return null when no tenant is configured', () async {
      final tenantId = await tenantService.loadTenant();
      expect(tenantId, isNull);
      expect(tenantService.currentTenantId, isNull);
      expect(tenantService.hasTenant, isFalse);
    });

    test('should save and load tenant ID', () async {
      const testTenantId = 'test-tenant-123';

      final saved = await tenantService.setTenant(testTenantId);
      expect(saved, isTrue);
      expect(tenantService.currentTenantId, equals(testTenantId));
      expect(tenantService.hasTenant, isTrue);

      // Create a new instance to test persistence
      final newService = TenantService();
      final loadedTenantId = await newService.loadTenant();
      expect(loadedTenantId, equals(testTenantId));
      expect(newService.currentTenantId, equals(testTenantId));
    });

    test('should clear tenant ID', () async {
      const testTenantId = 'test-tenant-123';

      await tenantService.setTenant(testTenantId);
      expect(tenantService.hasTenant, isTrue);

      final cleared = await tenantService.clearTenant();
      expect(cleared, isTrue);
      expect(tenantService.currentTenantId, isNull);
      expect(tenantService.hasTenant, isFalse);
    });

    test('should get last tenant ID after setting tenant', () async {
      const testTenantId = 'test-tenant-123';

      await tenantService.setTenant(testTenantId);
      final lastTenantId = await tenantService.getLastTenantId();
      expect(lastTenantId, equals(testTenantId));
    });

    test('should update tenant ID when setting a new one', () async {
      const firstTenantId = 'tenant-1';
      const secondTenantId = 'tenant-2';

      await tenantService.setTenant(firstTenantId);
      expect(tenantService.currentTenantId, equals(firstTenantId));

      await tenantService.setTenant(secondTenantId);
      expect(tenantService.currentTenantId, equals(secondTenantId));

      final lastTenantId = await tenantService.getLastTenantId();
      expect(lastTenantId, equals(secondTenantId));
    });

    test('should handle empty tenant ID', () async {
      final saved = await tenantService.setTenant('');
      expect(saved, isTrue);
      expect(tenantService.currentTenantId, equals(''));
      expect(
        tenantService.hasTenant,
        isFalse,
      ); // Empty string is not considered valid
    });
  });
}
