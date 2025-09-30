import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/recent_activity_model.dart';
import '../../domain/services/student_service.dart';

// Service provider
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});

// Recent activities provider
final recentActivitiesProvider = FutureProvider<List<RecentActivityModel>>((
  ref,
) async {
  final service = ref.watch(studentServiceProvider);
  return service.getRecentActivities();
});

// Student info provider
final studentInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  return service.getStudentInfo();
});
