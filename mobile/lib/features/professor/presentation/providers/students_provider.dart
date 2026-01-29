import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/students_repository.dart';
import '../../infrastructure/repositories/students_repository_impl.dart';
import '../../domain/models/student_model.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepositoryImpl();
});

final studentsListProvider = FutureProvider.autoDispose<List<StudentModel>>((
  ref,
) async {
  final repository = ref.read(studentsRepositoryProvider);
  return repository.getStudentsList();
});

final studentProfileProvider = FutureProvider.autoDispose
    .family<StudentModel?, String>((ref, studentId) async {
  final repository = ref.read(studentsRepositoryProvider);
  return repository.getStudentProfile(studentId);
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
