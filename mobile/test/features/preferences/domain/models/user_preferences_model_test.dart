import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/preferences/domain/models/user_preferences_model.dart';

void main() {
  group('UserPreferencesModel', () {
    test('should parse from JSON correctly', () {
      final json = {
        'favoriteProfessors': [
          {
            'id': 'prof-1',
            'name': 'Profesor Juan',
            'email': 'juan@example.com',
            'specialties': ['Tennis', 'Padel'],
          },
        ],
        'favoriteTenants': [
          {
            'id': 'tenant-1',
            'name': 'Centro A',
            'slug': 'centro-a',
            'logo': 'logo.png',
            'isActive': true,
          },
        ],
      };

      final preferences = UserPreferencesModel.fromJson(json);

      expect(preferences.favoriteProfessors.length, 1);
      expect(preferences.favoriteProfessors.first.id, 'prof-1');
      expect(preferences.favoriteProfessors.first.name, 'Profesor Juan');
      expect(preferences.favoriteTenants.length, 1);
      expect(preferences.favoriteTenants.first.id, 'tenant-1');
      expect(preferences.favoriteTenants.first.name, 'Centro A');
    });

    test('should handle empty lists', () {
      final json = {'favoriteProfessors': [], 'favoriteTenants': []};

      final preferences = UserPreferencesModel.fromJson(json);

      expect(preferences.favoriteProfessors, isEmpty);
      expect(preferences.favoriteTenants, isEmpty);
    });

    test('should convert to JSON correctly', () {
      final preferences = UserPreferencesModel(
        favoriteProfessors: [
          FavoriteProfessor(
            id: 'prof-1',
            name: 'Profesor Juan',
            email: 'juan@example.com',
            specialties: ['Tennis'],
          ),
        ],
        favoriteTenants: [
          FavoriteTenant(
            id: 'tenant-1',
            name: 'Centro A',
            slug: 'centro-a',
            isActive: true,
          ),
        ],
      );

      final json = preferences.toJson();

      expect(json['favoriteProfessors'], isA<List>());
      expect(json['favoriteTenants'], isA<List>());
    });

    test('should copy with new values', () {
      final original = UserPreferencesModel(
        favoriteProfessors: [
          FavoriteProfessor(
            id: 'prof-1',
            name: 'Profesor Juan',
            email: 'juan@example.com',
            specialties: [],
          ),
        ],
        favoriteTenants: [],
      );

      final updated = original.copyWith(
        favoriteTenants: [
          FavoriteTenant(
            id: 'tenant-1',
            name: 'Centro A',
            slug: 'centro-a',
            isActive: true,
          ),
        ],
      );

      expect(updated.favoriteProfessors.length, 1);
      expect(updated.favoriteTenants.length, 1);
    });
  });

  group('FavoriteProfessor', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': 'prof-1',
        'name': 'Profesor Juan',
        'email': 'juan@example.com',
        'specialties': ['Tennis', 'Padel'],
      };

      final professor = FavoriteProfessor.fromJson(json);

      expect(professor.id, 'prof-1');
      expect(professor.name, 'Profesor Juan');
      expect(professor.email, 'juan@example.com');
      expect(professor.specialties.length, 2);
    });

    test('should handle empty specialties', () {
      final json = {
        'id': 'prof-1',
        'name': 'Profesor Juan',
        'email': 'juan@example.com',
        'specialties': [],
      };

      final professor = FavoriteProfessor.fromJson(json);

      expect(professor.specialties, isEmpty);
    });
  });

  group('FavoriteTenant', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': 'tenant-1',
        'name': 'Centro A',
        'slug': 'centro-a',
        'logo': 'logo.png',
        'isActive': true,
      };

      final tenant = FavoriteTenant.fromJson(json);

      expect(tenant.id, 'tenant-1');
      expect(tenant.name, 'Centro A');
      expect(tenant.slug, 'centro-a');
      expect(tenant.logo, 'logo.png');
      expect(tenant.isActive, true);
    });

    test('should handle null logo', () {
      final json = {
        'id': 'tenant-1',
        'name': 'Centro A',
        'slug': 'centro-a',
        'isActive': true,
      };

      final tenant = FavoriteTenant.fromJson(json);

      expect(tenant.logo, isNull);
    });
  });
}
