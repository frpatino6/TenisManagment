import '../../../../core/logging/logger.dart';
import '../domain/dtos/create_tournament_dto.dart';
import '../domain/dtos/update_tournament_dto.dart';
import '../domain/models/bracket_model.dart';
import '../domain/models/tournament_model.dart';
import '../domain/repositories/tournament_repository.dart';

/// Implementación mock del repositorio de torneos para desarrollo.
/// TODO: Reemplazar con implementación HTTP real.
class MockTournamentRepository implements TournamentRepository {
  final _logger = AppLogger.tag('MockTournamentRepository');

  @override
  Future<List<TournamentModel>> getTournaments() async {
    _logger.debug('Obteniendo lista de torneos (MOCK)');

    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Retornar lista de torneos mock
    return [
      TournamentModel(
        id: '1',
        name: 'Torneo de Verano 2024',
        description:
            'El torneo más grande de la temporada. Incluye premios en efectivo y trofeos para todas las categorías.',
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        status: TournamentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categories: [
          _createCategory('c1', '1', 'Single Masculino A', CategoryGender.male),
          _createCategory(
            'c2',
            '1',
            'Single Femenino B',
            CategoryGender.female,
          ),
          _createCategory('c3', '1', 'Dobles Mixto', CategoryGender.mixed),
        ],
      ),
      TournamentModel(
        id: '2',
        name: 'Campeonato Primavera',
        description: 'Torneo clasificatorio para el ranking nacional.',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        status: TournamentStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        categories: [
          _createCategory(
            'c4',
            '2',
            'Single Masculino Pro',
            CategoryGender.male,
          ),
          _createCategory(
            'c5',
            '2',
            'Single Femenino Pro',
            CategoryGender.female,
          ),
        ],
      ),
      TournamentModel(
        id: '3',
        name: 'Copa Invierno 2023',
        description: 'Torneo anual de invierno.',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 55)),
        status: TournamentStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
        updatedAt: DateTime.now().subtract(const Duration(days: 70)),
        categories: [
          _createCategory('c6', '3', 'Single General', CategoryGender.mixed),
        ],
      ),
    ];
  }

  TournamentCategoryModel _createCategory(
    String id,
    String tournamentId,
    String name,
    CategoryGender gender,
  ) {
    return TournamentCategoryModel(
      id: id,
      name: name,
      gender: gender,
      participants: [], // Lista vacía por defecto
    );
  }

  @override
  Future<TournamentModel> getTournamentById(String id) async {
    _logger.debug('Obteniendo torneo (MOCK)', {'tournamentId': id});

    await Future.delayed(const Duration(seconds: 1));

    throw UnimplementedError('Mock: getTournamentById not implemented');
  }

  @override
  Future<BracketModel?> getBracket(
    String tournamentId,
    String categoryId,
  ) async {
    _logger.debug('Obteniendo bracket (MOCK)', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    await Future.delayed(const Duration(seconds: 1));

    return _generateMockBracket(tournamentId, categoryId);
  }

  static List<BracketMatchModel>? _mockMatches;

  BracketModel _generateMockBracket(String tournamentId, String categoryId) {
    if (_mockMatches != null) {
      return BracketModel(
        id: 'mock-bracket-1',
        tournamentId: tournamentId,
        categoryId: categoryId,
        matches: _mockMatches!,
        status: BracketStatus.inProgress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Generar bracket inicial si no existe
    final matches = <BracketMatchModel>[];

    // Ronda 4 (Octavos) - 8 matches
    for (int i = 0; i < 8; i++) {
      final p1 = i < 5 ? 'Jugador ${i * 2 + 1}' : null;
      final p2 = i < 5 ? 'Jugador ${i * 2 + 2}' : null;

      matches.add(
        BracketMatchModel(
          id: 'o$i',
          round: 4,
          position: i,
          player1Id: p1,
          player1Name: p1,
          player2Id: p2,
          player2Name: p2,
          nextMatchId: 'q${i ~/ 2}',
        ),
      );
    }

    // Ronda 3 (Cuartos) - 4 matches
    for (int i = 0; i < 4; i++) {
      matches.add(
        BracketMatchModel(
          id: 'q$i',
          round: 3,
          position: i,
          nextMatchId: 's${i ~/ 2}',
        ),
      );
    }

    // Ronda 2 (Semifinales)
    matches.add(
      const BracketMatchModel(
        id: 's0',
        round: 2,
        position: 0,
        nextMatchId: 'f0',
      ),
    );
    matches.add(
      const BracketMatchModel(
        id: 's1',
        round: 2,
        position: 1,
        nextMatchId: 'f0',
      ),
    );

    // Ronda 1 (Final)
    matches.add(const BracketMatchModel(id: 'f0', round: 1, position: 0));

    // Aplicar avances automáticos por BYE inicial
    for (final m in List<BracketMatchModel>.from(matches)) {
      if (m.round == 4 && (m.player1Id == null || m.player2Id == null)) {
        final winner = m.player1Id ?? m.player2Id;
        if (winner != null) {
          final idx = matches.indexOf(m);
          matches[idx] = m.copyWith(winnerId: winner, score: 'BYE');
          _advanceInList(matches, m.id, winner);
        }
      }
    }

    _mockMatches = matches;

    return BracketModel(
      id: 'mock-bracket-1',
      tournamentId: tournamentId,
      categoryId: categoryId,
      matches: matches,
      status: BracketStatus.inProgress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _advanceInList(
    List<BracketMatchModel> matches,
    String matchId,
    String winnerId,
  ) {
    final match = matches.firstWhere((m) => m.id == matchId);
    if (match.nextMatchId == null) return;

    final nextMatchIdx = matches.indexWhere((m) => m.id == match.nextMatchId);
    if (nextMatchIdx == -1) return;

    final nextMatch = matches[nextMatchIdx];
    if (match.position % 2 == 0) {
      matches[nextMatchIdx] = nextMatch.copyWith(
        player1Id: winnerId,
        player1Name: winnerId,
      );
    } else {
      matches[nextMatchIdx] = nextMatch.copyWith(
        player2Id: winnerId,
        player2Name: winnerId,
      );
    }
  }

  @override
  Future<void> enrollInCategory(String tournamentId, String categoryId) async {
    _logger.debug('Inscribiendo usuario (MOCK)', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    await Future.delayed(const Duration(milliseconds: 500));

    _logger.info('Usuario inscrito exitosamente (MOCK)');
  }

  @override
  Future<BracketModel> generateBracket(
    String tournamentId,
    String categoryId,
  ) async {
    _logger.debug('Generando bracket (MOCK)', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });

    await Future.delayed(const Duration(seconds: 2));

    return _generateMockBracket(tournamentId, categoryId);
  }

  @override
  Future<BracketModel> recordMatchResult({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String score,
  }) async {
    _logger.debug('Registrando resultado (MOCK)', {
      'tournamentId': tournamentId,
      'matchId': matchId,
    });

    await Future.delayed(const Duration(seconds: 1));

    if (_mockMatches != null) {
      final idx = _mockMatches!.indexWhere((m) => m.id == matchId);
      if (idx != -1) {
        final match = _mockMatches![idx];
        final winnerName = winnerId == match.player1Id
            ? match.player1Name
            : match.player2Name;

        _mockMatches![idx] = match.copyWith(
          winnerId: winnerId,
          winnerName: winnerName,
          score: score,
        );

        _advanceInList(_mockMatches!, matchId, winnerId);
      }
    }

    return _generateMockBracket(tournamentId, 'mock-cat');
  }

  @override
  Future<TournamentModel> createTournament(CreateTournamentDto dto) async {
    _logger.debug('Creando torneo (MOCK)', {'name': dto.name});

    await Future.delayed(const Duration(seconds: 1));

    return TournamentModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: dto.name,
      description: dto.description,
      startDate: dto.startDate,
      endDate: dto.endDate,
      status: TournamentStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categories: dto.categories
          .map(
            (c) => TournamentCategoryModel(
              id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
              name: c.name,
              gender: c.gender,
              participants: [],
            ),
          )
          .toList(),
    );
  }

  @override
  Future<TournamentModel> updateTournament(
    String id,
    UpdateTournamentDto dto,
  ) async {
    _logger.debug('Actualizando torneo (MOCK)', {'tournamentId': id});

    await Future.delayed(const Duration(seconds: 1));

    return TournamentModel(
      id: id,
      name: dto.name ?? 'Torneo Actualizado',
      description: dto.description ?? 'Descripción actualizada',
      startDate: dto.startDate ?? DateTime.now(),
      endDate: dto.endDate ?? DateTime.now().add(const Duration(days: 7)),
      status: TournamentStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categories:
          dto.categories?.map((c) {
            return TournamentCategoryModel(
              id: c.id,
              name: c.name ?? 'Categoría',
              gender: c.gender ?? CategoryGender.mixed,
              participants: [],
              format: c.format ?? TournamentFormat.singleElimination,
            );
          }).toList() ??
          [],
    );
  }

  @override
  Future<void> deleteBracket(String tournamentId, String categoryId) async {
    _logger.debug('Eliminando bracket (MOCK)', {
      'tournamentId': tournamentId,
      'categoryId': categoryId,
    });
    await Future.delayed(const Duration(milliseconds: 500));
    _mockMatches = null;
  }
}
