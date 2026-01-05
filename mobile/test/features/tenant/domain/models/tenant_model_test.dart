import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';

void main() {
  group('TenantModel', () {
    final validJson = {
      'id': 'tenant-123',
      'name': 'Centro Deportivo',
      'slug': 'centro-deportivo',
      'domain': 'centro.example.com',
      'isActive': true,
      'logo': 'https://example.com/logo.png',
      'config': {'theme': 'dark'},
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-02T00:00:00.000Z',
    };

    test('should create TenantModel from valid JSON', () {
      final tenant = TenantModel.fromJson(validJson);
      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Centro Deportivo'));
      expect(tenant.slug, equals('centro-deportivo'));
      expect(tenant.domain, equals('centro.example.com'));
      expect(tenant.isActive, isTrue);
      expect(tenant.logo, equals('https://example.com/logo.png'));
      expect(tenant.config, isNotNull);
      expect(tenant.createdAt, isNotNull);
      expect(tenant.updatedAt, isNotNull);
    });

    test('should handle missing optional fields', () {
      final jsonWithoutOptionals = {
        'id': 'tenant-123',
        'name': 'Centro Deportivo',
        'slug': 'centro-deportivo',
        'isActive': true,
      };

      final tenant = TenantModel.fromJson(jsonWithoutOptionals);
      expect(tenant.domain, isNull);
      expect(tenant.logo, isNull);
      expect(tenant.config, isNull);
      expect(tenant.createdAt, isNull);
      expect(tenant.updatedAt, isNull);
    });

    test('should use default isActive when not provided', () {
      final jsonWithoutIsActive = {
        'id': 'tenant-123',
        'name': 'Centro Deportivo',
        'slug': 'centro-deportivo',
      };

      final tenant = TenantModel.fromJson(jsonWithoutIsActive);
      expect(tenant.isActive, isTrue);
    });

    test('should handle alternative JSON field names', () {
      final jsonWithAlternatives = {
        'tenantId': 'tenant-123',
        'tenantName': 'Centro Deportivo',
        'tenantSlug': 'centro-deportivo',
        'isActive': true,
      };

      final tenant = TenantModel.fromJson(jsonWithAlternatives);
      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Centro Deportivo'));
      expect(tenant.slug, equals('centro-deportivo'));
    });

    test('should extract logo from config if not directly provided', () {
      final jsonWithLogoInConfig = {
        'id': 'tenant-123',
        'name': 'Centro Deportivo',
        'slug': 'centro-deportivo',
        'isActive': true,
        'config': {'logo': 'https://example.com/logo.png'},
      };

      final tenant = TenantModel.fromJson(jsonWithLogoInConfig);
      expect(tenant.logo, equals('https://example.com/logo.png'));
    });

    test('should convert TenantModel to JSON', () {
      final tenant = TenantModel(
        id: 'tenant-123',
        name: 'Centro Deportivo',
        slug: 'centro-deportivo',
        domain: 'centro.example.com',
        isActive: true,
        logo: 'https://example.com/logo.png',
        config: {'theme': 'dark'},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = tenant.toJson();
      expect(json['id'], equals('tenant-123'));
      expect(json['name'], equals('Centro Deportivo'));
      expect(json['slug'], equals('centro-deportivo'));
      expect(json['domain'], equals('centro.example.com'));
      expect(json['isActive'], isTrue);
      expect(json['logo'], equals('https://example.com/logo.png'));
      expect(json['config'], equals({'theme': 'dark'}));
    });

    test('should handle empty string fallbacks', () {
      final jsonWithEmptyStrings = {
        'id': '',
        'name': '',
        'slug': '',
        'isActive': true,
      };

      final tenant = TenantModel.fromJson(jsonWithEmptyStrings);
      expect(tenant.id, equals(''));
      expect(tenant.name, equals(''));
      expect(tenant.slug, equals(''));
    });
  });
}
