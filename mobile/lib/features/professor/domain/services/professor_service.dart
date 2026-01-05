import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/logging/logger.dart';
import '../models/professor_model.dart';
import '../models/student_summary_model.dart';
import '../models/class_schedule_model.dart';

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

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _logger = AppLogger.tag('ProfessorService');

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

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

  Future<List<StudentSummaryModel>> getStudents() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

  Future<List<ClassScheduleModel>> getTodaySchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
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

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedule/by-date?date=$dateStr',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
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

  Future<List<ClassScheduleModel>> getWeekSchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/week'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Error al obtener horarios de la semana: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEarningsStats() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/earnings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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
      final response = await http.put(
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

  Future<void> confirmClass(String classId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/$classId/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

  Future<void> cancelClass(String classId, String reason) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/$classId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason}),
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

  /// Create a new schedule
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

      final response = await http.post(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(requestBody),
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

  /// Get all schedules for the professor
  Future<List<dynamic>> getMySchedules() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items;
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

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http.delete(
        Uri.parse('$_baseUrl/professor-dashboard/schedules/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedules/$scheduleId/block'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason}),
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
  Future<void> unblockSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/unblock',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

  /// Mark a class as completed
  Future<void> completeClass(String scheduleId, {double? paymentAmount}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/complete',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'paymentAmount': paymentAmount}),
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

  /// Cancel a booking
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

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/cancel-booking',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason, 'penaltyAmount': penaltyAmount}),
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
  Future<void> joinTenant(String tenantId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse('$_baseUrl/professor-dashboard/tenants/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'tenantId': tenantId}),
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
