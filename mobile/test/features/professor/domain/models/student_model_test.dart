import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/professor/domain/models/student_model.dart';
import 'package:tennis_management/core/exceptions/validation_exception.dart';

void main() {
  group('StudentModel', () {
    final validJson = {
      'id': 'student-123',
      'name': 'María García',
      'email': 'maria@example.com',
      'phone': '+1234567890',
      'membershipType': 'premium',
      'balance': 100.0,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-02T00:00:00.000Z',
    };

    test('should create StudentModel from valid JSON', () {
      final student = StudentModel.fromJson(validJson);
      expect(student.id, equals('student-123'));
      expect(student.name, equals('María García'));
      expect(student.email, equals('maria@example.com'));
      expect(student.phone, equals('+1234567890'));
      expect(student.membershipType, equals(MembershipType.premium));
      expect(student.balance, equals(100.0));
      expect(student.createdAt, isNotNull);
      expect(student.updatedAt, isNotNull);
    });

    test('should handle missing optional fields', () {
      final jsonWithoutOptionals = {
        'id': 'student-123',
        'name': 'María García',
        'email': 'maria@example.com',
        'membershipType': 'basic',
        'balance': 0.0,
      };
      
      final student = StudentModel.fromJson(jsonWithoutOptionals);
      expect(student.phone, isNull);
      expect(student.createdAt, isNull);
      expect(student.updatedAt, isNull);
      expect(student.membershipType, equals(MembershipType.basic));
    });

    test('should use default membershipType for unknown value', () {
      final jsonWithUnknownType = {
        'id': 'student-123',
        'name': 'María García',
        'email': 'maria@example.com',
        'membershipType': 'unknown',
        'balance': 0.0,
      };
      
      final student = StudentModel.fromJson(jsonWithUnknownType);
      expect(student.membershipType, equals(MembershipType.basic));
    });

    test('should convert StudentModel to JSON', () {
      final student = StudentModel(
        id: 'student-123',
        name: 'María García',
        email: 'maria@example.com',
        phone: '+1234567890',
        membershipType: MembershipType.premium,
        balance: 100.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );
      
      final json = student.toJson();
      expect(json['id'], equals('student-123'));
      expect(json['name'], equals('María García'));
      expect(json['email'], equals('maria@example.com'));
      expect(json['phone'], equals('+1234567890'));
      expect(json['membershipType'], equals('premium'));
      expect(json['balance'], equals(100.0));
    });

    test('should copy with new values', () {
      final student = StudentModel(
        id: 'student-123',
        name: 'María García',
        email: 'maria@example.com',
        membershipType: MembershipType.basic,
        balance: 100.0,
      );
      
      final updated = student.copyWith(
        name: 'María López',
        balance: 200.0,
      );
      
      expect(updated.id, equals('student-123'));
      expect(updated.name, equals('María López'));
      expect(updated.email, equals('maria@example.com'));
      expect(updated.balance, equals(200.0));
      expect(updated.membershipType, equals(MembershipType.basic));
    });

    test('should return correct membershipTypeDisplayName', () {
      final basicStudent = StudentModel(
        id: 'student-123',
        name: 'María García',
        email: 'maria@example.com',
        membershipType: MembershipType.basic,
        balance: 0.0,
      );
      
      final premiumStudent = StudentModel(
        id: 'student-456',
        name: 'Juan Pérez',
        email: 'juan@example.com',
        membershipType: MembershipType.premium,
        balance: 0.0,
      );
      
      expect(basicStudent.membershipTypeDisplayName, equals('Básico'));
      expect(premiumStudent.membershipTypeDisplayName, equals('Premium'));
    });

    test('should return correct initials', () {
      final studentWithTwoNames = StudentModel(
        id: 'student-123',
        name: 'María García',
        email: 'maria@example.com',
        membershipType: MembershipType.basic,
        balance: 0.0,
      );
      
      final studentWithOneName = StudentModel(
        id: 'student-456',
        name: 'Juan',
        email: 'juan@example.com',
        membershipType: MembershipType.basic,
        balance: 0.0,
      );
      
      expect(studentWithTwoNames.initials, equals('MG'));
      expect(studentWithOneName.initials, equals('J'));
    });

    test('should throw AssertionError for empty id in debug mode', () {
      final invalidJson = {
        'id': '',
        'name': 'María García',
        'email': 'maria@example.com',
        'membershipType': 'basic',
        'balance': 0.0,
      };
      
      expect(
        () => StudentModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for empty name in debug mode', () {
      final invalidJson = {
        'id': 'student-123',
        'name': '',
        'email': 'maria@example.com',
        'membershipType': 'basic',
        'balance': 0.0,
      };
      
      expect(
        () => StudentModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

