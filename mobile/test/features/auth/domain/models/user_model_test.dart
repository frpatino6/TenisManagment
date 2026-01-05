import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    final validJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'name': 'Juan Pérez',
      'phone': '+1234567890',
      'role': 'professor',
      'profileImageUrl': 'https://example.com/image.jpg',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-02T00:00:00.000Z',
    };

    test('should create UserModel from valid JSON', () {
      final user = UserModel.fromJson(validJson);
      expect(user.id, equals('user-123'));
      expect(user.email, equals('test@example.com'));
      expect(user.name, equals('Juan Pérez'));
      expect(user.phone, equals('+1234567890'));
      expect(user.role, equals('professor'));
      expect(user.profileImageUrl, equals('https://example.com/image.jpg'));
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('should handle missing optional fields', () {
      final jsonWithoutOptionals = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'Juan Pérez',
        'role': 'student',
      };

      final user = UserModel.fromJson(jsonWithoutOptionals);
      expect(user.phone, isNull);
      expect(user.profileImageUrl, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('should convert UserModel to JSON', () {
      final user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        phone: '+1234567890',
        role: 'professor',
        profileImageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = user.toJson();
      expect(json['id'], equals('user-123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['name'], equals('Juan Pérez'));
      expect(json['phone'], equals('+1234567890'));
      expect(json['role'], equals('professor'));
      expect(json['profileImageUrl'], equals('https://example.com/image.jpg'));
    });

    test('should copy with new values', () {
      final user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'professor',
      );

      final updated = user.copyWith(
        name: 'Juan López',
        email: 'juan@example.com',
      );

      expect(updated.id, equals('user-123'));
      expect(updated.name, equals('Juan López'));
      expect(updated.email, equals('juan@example.com'));
      expect(updated.role, equals('professor'));
    });

    test('should return correct isProfessor value', () {
      final professor = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'professor',
      );

      final student = UserModel(
        id: 'user-456',
        email: 'test2@example.com',
        name: 'María García',
        role: 'student',
      );

      expect(professor.isProfessor, isTrue);
      expect(professor.isStudent, isFalse);
      expect(student.isProfessor, isFalse);
      expect(student.isStudent, isTrue);
    });

    test('should have correct toString representation', () {
      final user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'professor',
      );

      final str = user.toString();
      expect(str, contains('user-123'));
      expect(str, contains('test@example.com'));
      expect(str, contains('Juan Pérez'));
      expect(str, contains('professor'));
    });

    test('should be equal when properties match', () {
      final user1 = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'professor',
      );

      final user2 = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Juan Pérez',
        role: 'professor',
      );

      expect(user1, equals(user2));
    });
  });
}
