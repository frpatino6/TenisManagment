import '../models/group_stage_model.dart';
import '../models/tournament_model.dart';

/// Repositorio para operaciones relacionadas con la fase de grupos de torneos.
abstract class GroupStageRepository {
  /// Genera grupos balanceados para una categoría de torneo.
  Future<GroupStageModel> generateGroups({
    required String tournamentId,
    required String categoryId,
    int? numberOfGroups,
    int? playersAdvancingPerGroup,
    SeedingMethod? seedingMethod,
  });

  /// Mueve un participante entre grupos (solo en estado DRAFT).
  Future<GroupStageModel> moveParticipantBetweenGroups({
    required String tournamentId,
    required String categoryId,
    required String participantId,
    required String fromGroupId,
    required String toGroupId,
  });

  /// Bloquea los grupos y genera los fixtures de Round Robin.
  Future<GroupStageModel> lockGroupsAndGenerateFixtures({
    required String tournamentId,
    required String categoryId,
  });

  /// Registra el resultado de un partido de grupo.
  Future<GroupStageModel> recordGroupMatchResult({
    required String tournamentId,
    required String categoryId,
    required String matchId,
    required String winnerId,
    required String score,
  });

  /// Avanza a la fase de eliminación directa.
  /// Genera el bracket basado en los clasificados de cada grupo.
  Future<void> advanceToKnockoutPhase({
    required String tournamentId,
    required String categoryId,
  });

  /// Obtiene el estado actual de la fase de grupos.
  Future<GroupStageModel?> getGroupStage({
    required String tournamentId,
    required String categoryId,
  });

  /// Elimina la fase de grupos de una categoría específica (Solo Admin).
  Future<void> deleteGroupStage({
    required String tournamentId,
    required String categoryId,
  });
}
