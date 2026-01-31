import '../dtos/create_tournament_dto.dart';
import '../dtos/update_tournament_dto.dart';
import '../models/bracket_model.dart';
import '../models/tournament_model.dart';

/// Repositorio para operaciones relacionadas con torneos.
abstract class TournamentRepository {
  /// Obtiene la lista de todos los torneos del tenant actual.
  Future<List<TournamentModel>> getTournaments();

  /// Obtiene un torneo específico por su ID.
  Future<TournamentModel> getTournamentById(String id);

  /// Obtiene el bracket de una categoría específica.
  /// Retorna null si el bracket no ha sido generado.
  Future<BracketModel?> getBracket(String tournamentId, String categoryId);

  /// Inscribe al usuario actual en una categoría de torneo.
  Future<void> enrollInCategory(String tournamentId, String categoryId);

  /// Genera el bracket para una categoría específica (Solo Admin).
  Future<BracketModel> generateBracket(String tournamentId, String categoryId);

  /// Registra el resultado de un partido de torneo (Solo Admin).
  Future<BracketModel> recordMatchResult({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String score,
  });

  /// Crea un nuevo torneo (Solo Admin).
  Future<TournamentModel> createTournament(CreateTournamentDto dto);

  /// Actualiza un torneo existente (Solo Admin).
  Future<TournamentModel> updateTournament(String id, UpdateTournamentDto dto);

  /// Elimina el bracket de una categoría específica (Solo Admin).
  Future<void> deleteBracket(String tournamentId, String categoryId);
}
