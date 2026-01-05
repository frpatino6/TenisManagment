import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/student/domain/models/recent_activity_model.dart';

void main() {
  group('RecentActivityModel', () {
    final validJson = {
      'id': 'activity-123',
      'type': 'booking',
      'title': 'Clase de Tenis',
      'description': 'Clase con Juan Pérez',
      'date': '2024-01-15T10:00:00.000Z',
      'status': 'confirmed',
      'icon': 'calendar',
      'color': 'blue',
    };

    test('should create RecentActivityModel from valid JSON', () {
      final activity = RecentActivityModel.fromJson(validJson);
      expect(activity.id, equals('activity-123'));
      expect(activity.type, equals('booking'));
      expect(activity.title, equals('Clase de Tenis'));
      expect(activity.description, equals('Clase con Juan Pérez'));
      expect(activity.status, equals('confirmed'));
      expect(activity.icon, equals('calendar'));
      expect(activity.color, equals('blue'));
    });

    test('should convert RecentActivityModel to JSON', () {
      final activity = RecentActivityModel.fromJson(validJson);
      final json = activity.toJson();

      expect(json['id'], equals('activity-123'));
      expect(json['type'], equals('booking'));
      expect(json['title'], equals('Clase de Tenis'));
      expect(json['description'], equals('Clase con Juan Pérez'));
      expect(json['status'], equals('confirmed'));
      expect(json['icon'], equals('calendar'));
      expect(json['color'], equals('blue'));
    });

    test('should format timeAgo correctly for recent times', () {
      final now = DateTime.now();

      // Test "Ahora" (less than 1 minute)
      final justNow = RecentActivityModel(
        id: 'activity-1',
        type: 'booking',
        title: 'Test',
        description: 'Test',
        date: now.subtract(const Duration(seconds: 30)),
        status: 'confirmed',
        icon: 'calendar',
        color: 'blue',
      );
      expect(justNow.timeAgo, equals('Ahora'));

      // Test minutes
      final minutesAgo = RecentActivityModel(
        id: 'activity-2',
        type: 'booking',
        title: 'Test',
        description: 'Test',
        date: now.subtract(const Duration(minutes: 30)),
        status: 'confirmed',
        icon: 'calendar',
        color: 'blue',
      );
      expect(minutesAgo.timeAgo, contains('min'));

      // Test hours
      final hoursAgo = RecentActivityModel(
        id: 'activity-3',
        type: 'booking',
        title: 'Test',
        description: 'Test',
        date: now.subtract(const Duration(hours: 2)),
        status: 'confirmed',
        icon: 'calendar',
        color: 'blue',
      );
      expect(hoursAgo.timeAgo, contains('hora'));

      // Test days
      final daysAgo = RecentActivityModel(
        id: 'activity-4',
        type: 'booking',
        title: 'Test',
        description: 'Test',
        date: now.subtract(const Duration(days: 3)),
        status: 'confirmed',
        icon: 'calendar',
        color: 'blue',
      );
      expect(daysAgo.timeAgo, contains('día'));
    });

    test('should handle different activity types', () {
      final types = ['booking', 'payment', 'service_request'];
      for (final type in types) {
        final json = {
          'id': 'activity-123',
          'type': type,
          'title': 'Test',
          'description': 'Test',
          'date': DateTime.now().toIso8601String(),
          'status': 'confirmed',
          'icon': 'calendar',
          'color': 'blue',
        };

        final activity = RecentActivityModel.fromJson(json);
        expect(activity.type, equals(type));
      }
    });
  });
}
