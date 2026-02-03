import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../domain/dtos/create_tournament_dto.dart';
import '../domain/dtos/update_tournament_dto.dart';
import '../domain/models/bracket_model.dart';
import '../domain/models/tournament_model.dart';
import '../domain/repositories/tournament_repository.dart';

/// Implementación del repositorio de torneos usando HTTP.
class TournamentRepositoryImpl implements TournamentRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final AppHttpClient _httpClient;
  final _logger = AppLogger.tag('TournamentRepository');

  TournamentRepositoryImpl(this._httpClient, {FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<List<TournamentModel>> getTournaments() async {
    _logger.debug('Obteniendo lista de torneos');

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

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tournaments'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al obtener torneos',
        statusCode: response.statusCode,
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    final tournaments = data
        .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
        .toList();

    _logger.info('Torneos obtenidos', {'count': tournaments.length});
    return tournaments;
  }

  @override
  Future<TournamentModel> getTournamentById(String id) async {
    _logger.debug('Obteniendo torneo', {'tournamentId': id});

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

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tournaments/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al obtener torneo',
        statusCode: response.statusCode,
      );
    }

    final tournament = TournamentModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Torneo obtenido', {
      'tournamentId': id,
      'name': tournament.name,
      'categoriesCount': tournament.categories.length,
      'categories': tournament.categories
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'hasGroupStage': c.hasGroupStage,
              'hasBracket': c.hasBracket,
            },
          )
          .toList(),
    });
    return tournament;
  }

  @override
  Future<BracketModel?> getBracket(
    String tournamentId,
    String categoryId,
  ) async {
    _logger.debug('Obteniendo bracket', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

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

    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/bracket',
      ),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 404) {
      _logger.info('Bracket no encontrado (404)', {
        'tournamentId': tournamentId,
        'categoryId': categoryId,
      });
      return null;
    }

    if (response.statusCode != 200) {
      throw NetworkException.serverError(
        message: 'Error al obtener bracket',
        statusCode: response.statusCode,
      );
    }

    final bracket = BracketModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Bracket obtenido', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'totalMatches': bracket.matches.length,
    });

    return bracket;
  }

  @override
  Future<void> enrollInCategory(String tournamentId, String categoryId) async {
    _logger.debug('Inscribiendo usuario en categoría', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

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

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/enroll',
      ),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Error al inscribir usuario';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          errorMessage = body['error'] as String;
        } else if (body.containsKey('message')) {
          errorMessage = body['message'] as String;
        }
      } catch (_) {
        // Ignorar error de parsing
      }

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    _logger.info('Usuario inscrito exitosamente', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });
  }

  @override
  Future<BracketModel> generateBracket(
    String tournamentId,
    String categoryId,
  ) async {
    _logger.debug('Generando bracket', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

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

    final response = await _httpClient.post(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/generate-bracket',
      ),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 201) {
      String errorMessage = 'Error al generar bracket';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          errorMessage = body['error'] as String;
        } else if (body.containsKey('message')) {
          errorMessage = body['message'] as String;
        }
      } catch (_) {
        // Ignorar error de parsing
      }

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final bracket = BracketModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Bracket generado exitosamente', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'totalMatches': bracket.matches.length,
    });

    return bracket;
  }

  @override
  Future<BracketModel> recordMatchResult({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String score,
  }) async {
    _logger.debug('Registrando resultado de partido', {
      'tournamentId': tournamentId,
      'matchId': matchId,
      'winnerId': winnerId,
    });

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

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/tournaments/$tournamentId/matches/$matchId/result'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'winnerId': winnerId, 'score': score}),
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Error al registrar resultado';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          errorMessage = body['error'] as String;
        } else if (body.containsKey('message')) {
          errorMessage = body['message'] as String;
        }
      } catch (_) {
        // Ignorar error de parsing
      }

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final bracket = BracketModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Resultado registrado exitosamente', {
      'tournamentId': tournamentId,
      'matchId': matchId,
    });

    return bracket;
  }

  @override
  Future<TournamentModel> createTournament(CreateTournamentDto dto) async {
    _logger.debug('Creando nuevo torneo', {'name': dto.name});

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

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/tournaments'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Error al crear torneo';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          errorMessage = body['error'] as String;
        } else if (body.containsKey('message')) {
          errorMessage = body['message'] as String;
        }
      } catch (_) {
        // Ignorar error de parsing
      }

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final tournament = TournamentModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Torneo creado exitosamente', {
      'tournamentId': tournament.id,
      'name': tournament.name,
    });

    return tournament;
  }

  @override
  Future<TournamentModel> updateTournament(
    String id,
    UpdateTournamentDto dto,
  ) async {
    _logger.debug('Actualizando torneo', {'tournamentId': id});

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

    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl/tournaments/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Error al actualizar torneo';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          errorMessage = body['error'] as String;
        } else if (body.containsKey('message')) {
          errorMessage = body['message'] as String;
        }
      } catch (_) {
        // Ignorar error de parsing
      }

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    final tournament = TournamentModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _logger.info('Torneo actualizado exitosamente', {
      'tournamentId': tournament.id,
      'name': tournament.name,
    });

    return tournament;
  }

  @override
  Future<void> deleteBracket(String tournamentId, String categoryId) async {
    _logger.debug('Eliminando bracket', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

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

    final response = await _httpClient.delete(
      Uri.parse(
        '$_baseUrl/tournaments/$tournamentId/categories/$categoryId/bracket',
      ),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String errorMessage = 'Error al eliminar bracket';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      } catch (_) {}

      throw NetworkException.serverError(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    _logger.info('Bracket eliminado exitosamente');
  }
}
