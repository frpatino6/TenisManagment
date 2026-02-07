import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';

void main() {
  group('CurrentTenantIdNotifier', () {
    test('should initialize with null', () {
      final container = ProviderContainer();
      final state = container.read(currentTenantIdProvider);

      expect(state, isNull);
    });

    test('should update tenant ID', () {
      final container = ProviderContainer();
      final notifier = container.read(currentTenantIdProvider.notifier);

      notifier.update('tenant-123');

      final state = container.read(currentTenantIdProvider);
      expect(state, equals('tenant-123'));
    });

    test('should update to null', () {
      final container = ProviderContainer();
      final notifier = container.read(currentTenantIdProvider.notifier);

      notifier.update('tenant-123');
      notifier.update(null);

      final state = container.read(currentTenantIdProvider);
      expect(state, isNull);
    });
  });

  group('hasTenantProvider', () {
    test('should return false when tenant ID is null', () {
      final container = ProviderContainer();
      final hasTenant = container.read(hasTenantProvider);

      expect(hasTenant, isFalse);
    });

    test('should return false when tenant ID is empty', () {
      final container = ProviderContainer();
      container.read(currentTenantIdProvider.notifier).update('');
      final hasTenant = container.read(hasTenantProvider);

      expect(hasTenant, isFalse);
    });

    test('should return true when tenant ID is set', () {
      final container = ProviderContainer();
      container.read(currentTenantIdProvider.notifier).update('tenant-123');
      final hasTenant = container.read(hasTenantProvider);

      expect(hasTenant, isTrue);
    });
  });
}
