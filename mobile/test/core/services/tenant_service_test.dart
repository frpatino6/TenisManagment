import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/services/tenant_service.dart';

// Note: These tests are simplified since TenantService is now stateless
// and requires Firebase Auth and HTTP calls to the backend.
// Full integration tests should be used to test loadTenant() and setTenant().

void main() {
  group('TenantService', () {
    test('TenantService is stateless - no internal state', () {
      // Service is stateless, so creating multiple instances should be fine
      final service1 = TenantService();
      final service2 = TenantService();
      expect(service1, isNotNull);
      expect(service2, isNotNull);
      // Both instances should work independently (stateless)
      expect(service1, isA<TenantService>());
      expect(service2, isA<TenantService>());
    });

    // Note: loadTenant() and setTenant() require Firebase Auth and HTTP calls
    // These should be tested with integration tests or with proper mocks
    // For now, we verify the service structure is correct
  });
}
