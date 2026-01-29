import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/providers/students_provider.dart';
import 'package:tennis_management/features/professor/domain/models/student_model.dart';

void main() {
  group('filteredStudentsProvider', () {
    test('should return all students when search query is empty', () async {
      final testStudents = [
        StudentModel(
          id: 'student-1',
          name: 'John Doe',
          email: 'john@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
        StudentModel(
          id: 'student-2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) async => testStudents,
          ),
        ],
      );

      // Wait for the future to complete
      await container.read(studentsListProvider.future);
      
      final filtered = container.read(filteredStudentsProvider(''));
      expect(filtered.length, equals(2));
      expect(filtered, equals(testStudents));
    });

    test('should return all students when search query is only whitespace', () async {
      final testStudents = [
        StudentModel(
          id: 'student-1',
          name: 'John Doe',
          email: 'john@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) async => testStudents,
          ),
        ],
      );

      await container.read(studentsListProvider.future);
      final filtered = container.read(filteredStudentsProvider('   '));
      expect(filtered.length, equals(1));
    });

    test('should filter students by name', () async {
      final testStudents = [
        StudentModel(
          id: 'student-1',
          name: 'John Doe',
          email: 'john@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
        StudentModel(
          id: 'student-2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) async => testStudents,
          ),
        ],
      );

      await container.read(studentsListProvider.future);
      final filtered = container.read(filteredStudentsProvider('John'));
      expect(filtered.length, equals(1));
      expect(filtered[0].name, equals('John Doe'));
    });

    test('should filter students by name case-insensitively', () async {
      final testStudents = [
        StudentModel(
          id: 'student-1',
          name: 'John Doe',
          email: 'john@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) async => testStudents,
          ),
        ],
      );

      await container.read(studentsListProvider.future);
      final filtered = container.read(filteredStudentsProvider('JOHN'));
      expect(filtered.length, equals(1));
    });

    test('should filter students by email', () async {
      final testStudents = [
        StudentModel(
          id: 'student-1',
          name: 'John Doe',
          email: 'john@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
        StudentModel(
          id: 'student-2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          membershipType: MembershipType.basic,
          balance: 0.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) async => testStudents,
          ),
        ],
      );

      await container.read(studentsListProvider.future);
      final filtered = container.read(filteredStudentsProvider('jane@'));
      expect(filtered.length, equals(1));
      expect(filtered[0].email, equals('jane@example.com'));
    });

    test('should return empty list when loading', () async {
      // Create a never-completing future to simulate loading state
      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) => Future<List<StudentModel>>.delayed(
              Duration(seconds: 10),
              () => [],
            ),
          ),
        ],
      );

      // Read immediately while still loading
      // The provider should return empty list during loading
      final filtered = container.read(filteredStudentsProvider('test'));
      expect(filtered, isEmpty);
    });

    test('should return empty list on error', () async {
      final container = ProviderContainer(
        overrides: [
          studentsListProvider.overrideWith(
            (ref) => Future<List<StudentModel>>.error('Error'),
          ),
        ],
      );

      // Wait a bit for the error to propagate
      await Future.delayed(Duration(milliseconds: 100));
      
      final filtered = container.read(filteredStudentsProvider('test'));
      expect(filtered, isEmpty);
    });
  });
}

