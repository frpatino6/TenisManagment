import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/students_service.dart';
import '../../domain/models/student_model.dart';

final studentsServiceProvider = Provider<StudentsService>((ref) {
  return StudentsService();
});

final studentsListProvider = FutureProvider<List<StudentModel>>((ref) async {
  final service = ref.read(studentsServiceProvider);
  return service.getStudentsList();
});

final studentProfileProvider = FutureProvider.family<StudentModel?, String>((
  ref,
  studentId,
) async {
  final service = ref.read(studentsServiceProvider);
  return service.getStudentProfile(studentId);
});

final filteredStudentsProvider = Provider.family<List<StudentModel>, String>((
  ref,
  searchQuery,
) {
  final studentsAsync = ref.watch(studentsListProvider);

  return studentsAsync.when(
    data: (students) {
      if (searchQuery.isEmpty) return students;

      final query = searchQuery.toLowerCase();
      return students.where((student) {
        return student.name.toLowerCase().contains(query) ||
            student.email.toLowerCase().contains(query);
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
