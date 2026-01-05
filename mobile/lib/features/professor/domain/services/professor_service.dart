import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/constants/timeouts.dart';
import '../models/professor_model.dart';
import '../models/student_summary_model.dart';
import '../models/class_schedule_model.dart';
import '../models/professor_schedule_model.dart';

/// Legacy exception - kept for backward compatibility
/// Use [ScheduleException] instead
@Deprecated('Use ScheduleException.conflict() instead')
class ScheduleConflictException extends ScheduleException {
  ScheduleConflictException(
    super.message, {
    super.conflictingTenantId,
    super.conflictingTenantName,
    super.warnings,
  }) : super(code: 'SCHEDULE_CONFLICT');
}

/// Service responsible for professor-related operations
/// Handles professor dashboard data, schedules, and student management
/// Manages API communication for professor-specific endpoints
class ProfessorService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth;
  final _logger = AppLogger.tag('ProfessorService');
  final http.Client _httpClient;

  ProfessorService({
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  /// Retrieves professor information and dashboard data
  /// Returns [ProfessorModel] with complete professor details
  /// Throws [Exception] if authentication fails or API request fails
  Future<ProfessorModel> getProfessorInfo() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh

      final url = '$_baseUrl/professor-dashboard/me';

      final response = await _httpClient
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _logger.debug('Información del profesor obtenida exitosamente');
        return ProfessorModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.warning('Error de autenticación al obtener información', {
          'statusCode': response.statusCode,
        });
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw DomainException.notFound(resource: 'Profesor');
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener información del profesor',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the list of students associated with the professor
  ///
  /// Returns a list of [StudentSummaryModel] containing student information
  /// such as name, email, progress, and membership type.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no students are found
  Future<List<StudentSummaryModel>> getStudents() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/students'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> studentsJson = data['items'] ?? [];
        return studentsJson
            .map((json) => StudentSummaryModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener estudiantes',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves today's schedule for the professor
  ///
  /// Returns a list of [ClassScheduleModel] representing all classes
  /// scheduled for today.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no classes are scheduled for today
  Future<List<ClassScheduleModel>> getTodaySchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/schedule/today'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] as List<dynamic>? ?? [];
        return classesJson
            .map(
              (json) =>
                  ClassScheduleModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener horarios',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the schedule for a specific date
  ///
  /// [date] The date to retrieve the schedule for
  ///
  /// Returns a list of [ClassScheduleModel] representing all classes
  /// scheduled for the specified date.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no classes are scheduled for the date
  Future<List<ClassScheduleModel>> getScheduleByDate(DateTime date) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final localDate = DateTime(date.year, date.month, date.day);
      final dateStr =
          '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedule/by-date?date=$dateStr',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] as List<dynamic>? ?? [];
        return classesJson
            .map(
              (json) =>
                  ClassScheduleModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener horarios',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the schedule for the current week
  ///
  /// Returns a list of [ClassScheduleModel] representing all classes
  /// scheduled for the current week (Monday to Sunday).
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no classes are scheduled for the week
  Future<List<ClassScheduleModel>> getWeekSchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/schedule/week'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] as List<dynamic>? ?? [];
        return classesJson
            .map(
              (json) =>
                  ClassScheduleModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener horarios de la semana',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves earnings statistics for the professor
  ///
  /// Returns a [Map] containing earnings data such as:
  /// - Total earnings
  /// - Earnings by period (daily, weekly, monthly)
  /// - Number of classes completed
  /// - Average earnings per class
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  Future<Map<String, dynamic>> getEarningsStats() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/earnings'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener estadísticas de ganancias',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the professor's profile information
  ///
  /// [name] The professor's full name
  /// [phone] The professor's phone number
  /// [specialties] List of specialties (e.g., ['Tenis', 'Padel'])
  /// [hourlyRate] The hourly rate charged by the professor
  /// [experienceYears] Number of years of experience
  ///
  /// Returns the updated [ProfessorModel] with the new information
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ValidationException] if any of the provided data is invalid
  /// Throws [NetworkException] if the API request fails
  Future<ProfessorModel> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
    required int experienceYears,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await _httpClient
          .put(
            Uri.parse('$_baseUrl/professor-dashboard/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({
              'name': name,
              'phone': phone,
              'specialties': specialties,
              'hourlyRate': hourlyRate,
              'experienceYears': experienceYears,
            }),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfessorModel.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw ValidationException(
          'Error de validación al actualizar perfil',
          code: 'VALIDATION_ERROR',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al actualizar perfil',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Confirms a scheduled class
  ///
  /// [classId] The ID of the class to confirm
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the class does not exist
  /// Throws [NetworkException] if the API request fails
  Future<void> confirmClass(String classId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await _httpClient
          .put(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedule/$classId/confirm',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: 'Error al confirmar clase',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancels a scheduled class
  ///
  /// [classId] The ID of the class to cancel
  /// [reason] The reason for cancellation (optional but recommended)
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the class does not exist
  /// Throws [NetworkException] if the API request fails
  Future<void> cancelClass(String classId, String reason) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await _httpClient
          .put(
            Uri.parse('$_baseUrl/professor-dashboard/schedule/$classId/cancel'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({'reason': reason}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: 'Error al cancelar clase',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new available schedule slot
  ///
  /// [date] The date for the schedule
  /// [startTime] The start time of the schedule slot
  /// [endTime] The end time of the schedule slot
  /// [tenantId] Optional tenant ID. If not provided, backend uses the first active tenant
  ///
  /// Returns a [Map] containing the created schedule data including the schedule ID
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.conflict] if there's a scheduling conflict
  /// Throws [ValidationException] if the schedule data is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Note: TEN-108 - This will change when tenant admin module is implemented
  Future<Map<String, dynamic>> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String?
    tenantId, // Optional tenantId - if not provided, backend will use first active tenant
  }) async {
    _logger.info('Creando horario', {
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'tenantId': tenantId,
    });
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final requestBody = <String, dynamic>{
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };

      if (tenantId != null && tenantId.isNotEmpty) {
        requestBody['tenantId'] = tenantId;
      }

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/professor-dashboard/schedules'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 201) {
        _logger.info('Horario creado exitosamente');
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return responseData;
      } else if (response.statusCode == 409) {
        _logger.warning('Conflicto de horarios detectado', {
          'statusCode': response.statusCode,
        });
        // Conflict error - same time in different center
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final error = errorBody['error'] as String?;
        final message = errorBody['message'] as String?;

        if (error == 'CONFLICT_SAME_TIME') {
          _logger.warning('Conflicto de horarios detectado', {
            'conflictingTenantId': errorBody['conflictingTenantId'],
          });
          throw ScheduleException.conflict(
            message:
                message ?? 'Ya tienes un horario a esta hora en otro centro',
            conflictingTenantId: errorBody['conflictingTenantId'] as String?,
            conflictingTenantName:
                errorBody['conflictingTenantName'] as String?,
            warnings: errorBody['warnings'] as List<dynamic>?,
          );
        }

        throw ScheduleException.conflict(
          message: message ?? 'Error al crear horario: conflicto de horarios',
        );
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorBody?['error'] as String? ??
            errorBody?['message'] as String? ??
            'Error al crear horario: ${response.statusCode}';

        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw ValidationException(errorMessage, code: 'VALIDATION_ERROR');
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all schedules for the professor
  ///
  /// Returns a list of [ProfessorScheduleModel] containing all
  /// available and booked schedules for the professor.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no schedules exist
  Future<List<ProfessorScheduleModel>> getMySchedules() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  ProfessorScheduleModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener horarios',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a schedule slot
  ///
  /// [scheduleId] The ID of the schedule to delete
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the schedule does not exist
  /// Throws [DomainException] if the schedule cannot be deleted (e.g., already booked)
  /// Throws [NetworkException] if the API request fails
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .delete(
            Uri.parse('$_baseUrl/professor-dashboard/schedules/$scheduleId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al eliminar horario';

        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Block a schedule
  Future<void> blockSchedule(String scheduleId, String reason) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .put(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedules/$scheduleId/block',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({'reason': reason}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al bloquear horario';

        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a schedule
  /// Unblocks a previously blocked schedule slot
  ///
  /// [scheduleId] The ID of the schedule to unblock
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the schedule does not exist
  /// Throws [NetworkException] if the API request fails
  Future<void> unblockSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .put(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedules/$scheduleId/unblock',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al desbloquear horario';

        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Marks a class as completed and optionally records payment
  ///
  /// [scheduleId] The ID of the schedule/class to complete
  /// [paymentAmount] Optional payment amount received for the class
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the schedule does not exist
  /// Throws [ValidationException] if payment amount is invalid (e.g., negative)
  /// Throws [NetworkException] if the API request fails
  Future<void> completeClass(String scheduleId, {double? paymentAmount}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .put(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedules/$scheduleId/complete',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({'paymentAmount': paymentAmount}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al completar clase';

        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancels a student's booking for a schedule
  ///
  /// [scheduleId] The ID of the schedule/booking to cancel
  /// [reason] Optional reason for cancellation
  /// [penaltyAmount] Optional penalty amount to apply
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ScheduleException.notFound] if the schedule does not exist
  /// Throws [NetworkException] if the API request fails
  Future<void> cancelBooking(
    String scheduleId, {
    String? reason,
    double? penaltyAmount,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .put(
            Uri.parse(
              '$_baseUrl/professor-dashboard/schedules/$scheduleId/cancel-booking',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({
              'reason': reason,
              'penaltyAmount': penaltyAmount,
            }),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode != 200) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al cancelar reserva';

        if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Join a tenant (center) as a professor
  /// TODO: TEN-108 - This will change when tenant admin module is implemented.
  /// Currently allows self-service join, but will require admin approval in the future.
  /// Joins a professor to a tenant (center)
  ///
  /// [tenantId] The ID of the tenant to join
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [TenantException] if the tenant does not exist or join fails
  /// Throws [NetworkException] if the API request fails
  ///
  /// Note: TEN-108 - This will change when tenant admin module is implemented
  Future<void> joinTenant(String tenantId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/professor-dashboard/tenants/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({'tenantId': tenantId}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorBody?['error'] as String? ??
            'Error al unirse al centro: ${response.statusCode}';

        if (response.statusCode == 404) {
          throw TenantException.notFound();
        } else if (response.statusCode == 409) {
          throw TenantException.alreadyJoined(
            tenantName: errorBody?['tenantName'] as String?,
          );
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
