import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../domain/models/group_stage_model.dart';
import '../domain/models/tournament_model.dart';
import '../domain/repositories/group_stage_repository.dart';

/// Implementación del repositorio de fase de grupos usando HTTP.
class GroupStageRepositoryImpl implements GroupStageRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final AppHttpClient _httpClient;
  final _logger = AppLogger.tag('GroupStageRepository');

  GroupStageRepositoryImpl(this._httpClient, {FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  Future<String> _getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException.notAuthenticated();
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null) {
      throw AuthException.tokenExpired(
        message: 'No se pudo obtener el token de autenticación',
      );
    }

    return idToken;
  }

  @override
  Future<GroupStageModel> generateGroups({
    required String tournamentId,
    required String categoryId,
    int? numberOfGroups,
    int? playersAdvancingPerGroup,
    SeedingMethod? seedingMethod,
  }) async {
    _logger.debug('Generando grupos', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'numberOfGroups': numberOfGroups,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/generate-groups',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (numberOfGroups != null) 'numberOfGroups': numberOfGroups,
        if (playersAdvancingPerGroup != null)
          'playersAdvancingPerGroup': playersAdvancingPerGroup,
        if (seedingMethod != null) 'seedingMethod': seedingMethod.value,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException.serverError(
        message: 'Error al generar grupos',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Grupos generados exitosamente');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<GroupStageModel> moveParticipantBetweenGroups({
    required String tournamentId,
    required String categoryId,
    required String participantId,
    required String fromGroupId,
    required String toGroupId,
  }) async {
    _logger.debug('Moviendo participante entre grupos', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'participantId': participantId,
      'fromGroupId': fromGroupId,
      'toGroupId': toGroupId,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.put(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups/move-participant',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'participantId': participantId,
        'fromGroupId': fromGroupId,
        'toGroupId': toGroupId,
      }),
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Error al mover participante';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      } catch (_) {}

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Participante movido exitosamente');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<GroupStageModel> swapParticipantsBetweenGroups({
    required String tournamentId,
    required String categoryId,
    required String participant1Id,
    required String group1Id,
    required String participant2Id,
    required String group2Id,
  }) async {
    _logger.debug('Intercambiando participantes entre grupos', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'participant1Id': participant1Id,
      'group1Id': group1Id,
      'participant2Id': participant2Id,
      'group2Id': group2Id,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.put(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups/swap-participants',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'participant1Id': participant1Id,
        'group1Id': group1Id,
        'participant2Id': participant2Id,
        'group2Id': group2Id,
      }),
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Error al intercambiar participantes';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      } catch (_) {}

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Participantes intercambiados exitosamente');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<GroupStageModel> lockGroupsAndGenerateFixtures({
    required String tournamentId,
    required String categoryId,
  }) async {
    _logger.debug('Bloqueando grupos y generando fixtures', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups/lock',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al bloquear grupos',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Grupos bloqueados y fixtures generados');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<GroupStageModel> recordGroupMatchResult({
    required String tournamentId,
    required String categoryId,
    required String matchId,
    required String winnerId,
    required String score,
  }) async {
    _logger.debug('Registrando resultado de partido de grupo', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'matchId': matchId,
      'winnerId': winnerId,
      'score': score,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups/matches/$matchId/result',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'winnerId': winnerId, 'score': score}),
    );

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al registrar resultado',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Resultado registrado exitosamente');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<void> advanceToKnockoutPhase({
    required String tournamentId,
    required String categoryId,
  }) async {
    _logger.debug('Avanzando a fase de eliminación directa', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/advance-to-knockout',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException.serverError(
        message: 'Error al avanzar a fase eliminatoria',
        statusCode: response.statusCode,
      );
    }

    _logger.info('Avanzado a fase eliminatoria exitosamente');
  }

  @override
  Future<GroupStageModel?> getGroupStage({
    required String tournamentId,
    required String categoryId,
  }) async {
    _logger.debug('Obteniendo fase de grupos', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 404) {
      _logger.debug('Fase de grupos no encontrada');
      return null;
    }

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al obtener fase de grupos',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Fase de grupos obtenida exitosamente');

    return GroupStageModel.fromJson(data);
  }

  @override
  Future<void> deleteGroupStage({
    required String tournamentId,
    required String categoryId,
  }) async {
    _logger.debug('Eliminando fase de grupos', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    final token = await _getAuthToken();

    final response = await _httpClient.delete(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/groups',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String errorMessage = 'Error al eliminar fase de grupos';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      } catch (_) {}

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    _logger.info('Fase de grupos eliminada exitosamente');
  }
}
