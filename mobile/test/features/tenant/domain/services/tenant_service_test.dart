import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';

void main() {
  group('TenantModel', () {
    test('should parse tenant model from JSON correctly', () {
      final json = {
        'id': 'tenant-123',
        'name': 'Centro A',
        'slug': 'centro-a',
        'domain': 'centroa.example.com',
        'isActive': true,
        'logo': 'https://example.com/logo.png',
        'config': {'logo': 'https://example.com/logo.png'},
        'createdAt': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-01T00:00:00Z',
      };

      final tenant = TenantModel.fromJson(json);

      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Centro A'));
      expect(tenant.slug, equals('centro-a'));
      expect(tenant.domain, equals('centroa.example.com'));
      expect(tenant.isActive, isTrue);
      expect(tenant.logo, equals('https://example.com/logo.png'));
    });

    test('should handle tenant model with missing optional fields', () {
      final json = {
        'id': 'tenant-123',
        'name': 'Centro B',
        'slug': 'centro-b',
        'isActive': true,
      };

      final tenant = TenantModel.fromJson(json);

      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Centro B'));
      expect(tenant.domain, isNull);
      expect(tenant.logo, isNull);
      expect(tenant.isActive, isTrue);
    });

    test('should convert tenant model to JSON correctly', () {
      final tenant = TenantModel(
        id: 'tenant-123',
        name: 'Centro A',
        slug: 'centro-a',
        isActive: true,
        logo: 'https://example.com/logo.png',
      );

      final json = tenant.toJson();

      expect(json['id'], equals('tenant-123'));
      expect(json['name'], equals('Centro A'));
      expect(json['slug'], equals('centro-a'));
      expect(json['isActive'], isTrue);
      expect(json['logo'], equals('https://example.com/logo.png'));
    });

    test('should handle alternative JSON format (tenantId, tenantName)', () {
      final json = {
        'tenantId': 'tenant-123',
        'tenantName': 'Centro C',
        'tenantSlug': 'centro-c',
        'isActive': true,
      };

      final tenant = TenantModel.fromJson(json);

      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Centro C'));
      expect(tenant.slug, equals('centro-c'));
    });
  });
}
