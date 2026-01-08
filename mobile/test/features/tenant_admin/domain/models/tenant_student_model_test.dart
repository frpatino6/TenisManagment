import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_student_model.dart';

void main() {
  group('TenantStudentModel', () {
    final json = {
      'id': 's1',
      'name': 'John Doe',
      'email': 'john@test.com',
      'phone': '123456789',
      'membershipType': 'premium',
      'balance': 150.5,
      'isActive': true,
      'joinedAt': '2024-01-01T10:00:00Z',
    };

    test('should create model from json', () {
      final model = TenantStudentModel.fromJson(json);

      expect(model.id, 's1');
      expect(model.name, 'John Doe');
      expect(model.email, 'john@test.com');
      expect(model.phone, '123456789');
      expect(model.membershipType, 'premium');
      expect(model.balance, 150.5);
      expect(model.isActive, true);
      expect(model.joinedAt, DateTime.parse('2024-01-01T10:00:00Z'));
    });

    test('should convert model to json', () {
      final model = TenantStudentModel.fromJson(json);
      final result = model.toJson();

      expect(result['id'], 's1');
      expect(result['name'], 'John Doe');
      expect(result['email'], 'john@test.com');
      expect(result['balance'], 150.5);
    });
  });

  group('TenantStudentDetailsModel', () {
    test('should create model from json with bookings', () {
      final json = {
        'id': 's1',
        'name': 'John Doe',
        'email': 'john@test.com',
        'membershipType': 'basic',
        'balance': 0.0,
        'isActive': true,
        'joinedAt': '2024-01-01T10:00:00Z',
        'recentBookings': [
          {
            'id': 'b1',
            'serviceType': 'court_rental',
            'status': 'confirmed',
            'price': 50.0,
            'bookingDate': '2024-01-01T10:00:00Z',
            'createdAt': '2024-01-01T10:00:00Z',
            'updatedAt': '2024-01-01T10:00:00Z',
          },
        ],
      };

      final model = TenantStudentDetailsModel.fromJson(json);

      expect(model.name, 'John Doe');
      expect(model.recentBookings.length, 1);
      expect(model.recentBookings[0].id, 'b1');
    });
  });
}
