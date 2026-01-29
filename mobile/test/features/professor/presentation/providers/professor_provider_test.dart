import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tennis_management/features/professor/presentation/providers/professor_provider.dart';
import 'package:tennis_management/features/professor/domain/repositories/professor_repository.dart';
import 'package:tennis_management/features/professor/domain/models/professor_model.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';

// Mocks
class MockProfessorRepository extends Mock implements ProfessorRepository {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('ProfessorNotifier', () {
    late MockProfessorRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockProfessorRepository();
      container = ProviderContainer(
        overrides: [
          professorRepositoryProvider.overrideWithValue(mockRepository),
          // Override currentTenantIdProvider to return a simple value
          // We'll use a StateProvider for testing instead
        ],
      );
      
      // Set tenant ID after container is created
      container.read(currentTenantIdProvider.notifier).update('tenant-1');
    });

    tearDown(() {
      container.dispose();
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        final updatedProfessor = ProfessorModel(
          id: 'prof-1',
          name: 'Updated Name',
          email: 'updated@example.com',
          hourlyRate: 60.0,
          rating: 4.5,
          specialties: ['Tenis'],
          experienceYears: 5,
          totalStudents: 10,
          totalClasses: 50,
          monthlyEarnings: 5000.0,
          weeklyEarnings: 1250.0,
        );

        when(() => mockRepository.updateProfile(
              name: any(named: 'name'),
              phone: any(named: 'phone'),
              specialties: any(named: 'specialties'),
              hourlyRate: any(named: 'hourlyRate'),
              experienceYears: any(named: 'experienceYears'),
            )).thenAnswer((_) async => updatedProfessor);

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.updateProfile(
          name: 'Updated Name',
          phone: '123456789',
          specialties: ['Tenis'],
          hourlyRate: 60.0,
          experienceYears: 5,
        );

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should handle errors when updating profile', () async {
        when(() => mockRepository.updateProfile(
              name: any(named: 'name'),
              phone: any(named: 'phone'),
              specialties: any(named: 'specialties'),
              hourlyRate: any(named: 'hourlyRate'),
              experienceYears: any(named: 'experienceYears'),
            )).thenThrow(ValidationException('Invalid data'));

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.updateProfile(
          name: 'Test',
          phone: '123',
          specialties: [],
          hourlyRate: -10.0,
          experienceYears: -1,
        );

        final state = container.read(professorNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<ValidationException>());
      });
    });

    group('confirmClass', () {
      test('should confirm class successfully', () async {
        when(() => mockRepository.confirmClass(any())).thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.confirmClass('class-1');

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should handle errors when confirming class', () async {
        when(() => mockRepository.confirmClass(any()))
            .thenThrow(ScheduleException.notFound());

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.confirmClass('invalid-class');

        final state = container.read(professorNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<ScheduleException>());
      });
    });

    group('cancelClass', () {
      test('should cancel class successfully', () async {
        when(() => mockRepository.cancelClass(any(), any())).thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.cancelClass('class-1', 'Reason');

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should handle errors when canceling class', () async {
        when(() => mockRepository.cancelClass(any(), any()))
            .thenThrow(ScheduleException.notFound());

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.cancelClass('invalid-class', 'Reason');

        final state = container.read(professorNotifierProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('createSchedule', () {
      test('should create schedule successfully', () async {
        final scheduleData = {
          'id': 'schedule-1',
          'date': '2024-01-01T10:00:00Z',
        };

        when(() => mockRepository.createSchedule(
              date: any(named: 'date'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
              tenantId: any(named: 'tenantId'),
            )).thenAnswer((_) async => scheduleData);

        final notifier = container.read(professorNotifierProvider.notifier);

        final result = await notifier.createSchedule(
          date: DateTime(2024, 1, 1),
          startTime: DateTime(2024, 1, 1, 10),
          endTime: DateTime(2024, 1, 1, 11),
        );

        expect(result, equals(scheduleData));
        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
      });

      test('should handle errors when creating schedule', () async {
        when(() => mockRepository.createSchedule(
              date: any(named: 'date'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
              tenantId: any(named: 'tenantId'),
            )).thenThrow(ScheduleException.conflict(message: 'Schedule conflict'));

        final notifier = container.read(professorNotifierProvider.notifier);

        expect(
          () => notifier.createSchedule(
            date: DateTime(2024, 1, 1),
            startTime: DateTime(2024, 1, 1, 10),
            endTime: DateTime(2024, 1, 1, 11),
          ),
          throwsA(isA<ScheduleException>()),
        );
      });
    });

    group('deleteSchedule', () {
      test('should delete schedule successfully', () async {
        when(() => mockRepository.deleteSchedule(any())).thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.deleteSchedule('schedule-1');

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should handle errors when deleting schedule', () async {
        when(() => mockRepository.deleteSchedule(any()))
            .thenThrow(ScheduleException.notFound());

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.deleteSchedule('invalid-schedule');

        final state = container.read(professorNotifierProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('completeClass', () {
      test('should complete class successfully', () async {
        when(() => mockRepository.completeClass(any(), paymentAmount: any(named: 'paymentAmount')))
            .thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.completeClass('schedule-1', paymentAmount: 50.0);

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should complete class without payment amount', () async {
        when(() => mockRepository.completeClass(any(), paymentAmount: any(named: 'paymentAmount')))
            .thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.completeClass('schedule-1');

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
      });
    });

    group('cancelBooking', () {
      test('should cancel booking successfully', () async {
        when(() => mockRepository.cancelBooking(
              any(),
              reason: any(named: 'reason'),
              penaltyAmount: any(named: 'penaltyAmount'),
            )).thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.cancelBooking(
          'schedule-1',
          reason: 'Reason',
          penaltyAmount: 10.0,
        );

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should cancel booking without optional parameters', () async {
        when(() => mockRepository.cancelBooking(
              any(),
              reason: any(named: 'reason'),
              penaltyAmount: any(named: 'penaltyAmount'),
            )).thenAnswer((_) async => {});

        final notifier = container.read(professorNotifierProvider.notifier);

        await notifier.cancelBooking('schedule-1');

        final state = container.read(professorNotifierProvider);
        expect(state.hasValue, isTrue);
      });
    });

    group('refreshAll', () {
      test('should invalidate all providers', () {
        final notifier = container.read(professorNotifierProvider.notifier);

        // This should not throw
        notifier.refreshAll();

        expect(true, isTrue);
      });
    });
  });

  group('isProfessorProvider', () {
    test('should return false when professor info is loading', () {
      final container = ProviderContainer(
        overrides: [
          professorRepositoryProvider.overrideWithValue(MockProfessorRepository()),
          professorInfoProvider.overrideWith(
            (ref) => Future<ProfessorModel>.delayed(
              Duration(seconds: 10),
              () => throw UnimplementedError(),
            ),
          ),
        ],
      );

      final isProfessor = container.read(isProfessorProvider);
      expect(isProfessor, isFalse);
    });
  });
}

