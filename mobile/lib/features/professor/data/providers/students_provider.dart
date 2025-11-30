import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/students_service.dart';
import '../../domain/models/student_model.dart';

final studentsServiceProvider = Provider<StudentsService>((ref) {
  return StudentsService();
});

final studentsListProvider = FutureProvider.autoDispose<List<StudentModel>>((
  ref,
) async {
  final service = ref.read(studentsServiceProvider);
  return service.getStudentsList();
});

final studentProfileProvider = FutureProvider.autoDispose
    .family<StudentModel?, String>((ref, studentId) async {
      final service = ref.read(studentsServiceProvider);
      return service.getStudentProfile(studentId);
    });

final filteredStudentsProvider = Provider.autoDispose.family<List<StudentModel>, String>((
  ref,
  searchQuery,
) {
  final studentsAsync = ref.watch(studentsListProvider);

  return studentsAsync.when(
    data: (students) {
      final trimmedQuery = searchQuery.trim();
      if (trimmedQuery.isEmpty) return students;

      final query = trimmedQuery.toLowerCase();
      
      return students.where((student) {
        final nameLower = student.name.toLowerCase();
        final emailLower = student.email.toLowerCase();
        
        return nameLower.contains(query) || emailLower.contains(query);
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
