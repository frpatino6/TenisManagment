import '../models/student_model.dart';

/// Repository interface for student-related data operations
///
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class StudentsRepository {
  /// Retrieves the complete list of students from the professor's endpoint
  /// Returns a list of [StudentModel] objects containing detailed student information
  Future<List<StudentModel>> getStudentsList();

  /// Retrieves a specific student's profile by ID
  /// [studentId] The unique identifier of the student
  /// Returns [StudentModel] if found, `null` if not found
  Future<StudentModel?> getStudentProfile(String studentId);
}
