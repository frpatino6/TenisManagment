import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/http_client.dart';
import '../../domain/models/group_stage_model.dart';
import '../../domain/models/tournament_model.dart';
import '../../domain/repositories/group_stage_repository.dart';
import '../../data/group_stage_repository_impl.dart';

part 'group_stage_provider.g.dart';

/// Provider del repositorio de fase de grupos.
@riverpod
GroupStageRepository groupStageRepository(Ref ref) {
  final httpClient = ref.read(appHttpClientProvider);
  return GroupStageRepositoryImpl(httpClient);
}

/// Provider para obtener la fase de grupos de una categoría.
@riverpod
Future<GroupStageModel?> groupStage(
  Ref ref, {
  required String tournamentId,
  required String categoryId,
}) async {
  final repository = ref.watch(groupStageRepositoryProvider);
  return repository.getGroupStage(
    tournamentId: tournamentId,
    categoryId: categoryId,
  );
}

/// Provider para generar grupos.
@riverpod
class GroupStageGenerator extends _$GroupStageGenerator {
  bool _mounted = true;

  @override
  FutureOr<GroupStageModel?> build() {
    ref.onDispose(() => _mounted = false);
    return null;
  }

  void _safeSetState(AsyncValue<GroupStageModel?> newState) {
    if (_mounted) {
      state = newState;
    }
  }

  /// Genera grupos balanceados para una categoría.
  Future<void> generateGroups({
    required String tournamentId,
    required String categoryId,
    int? numberOfGroups,
    int? playersAdvancingPerGroup,
    SeedingMethod? seedingMethod,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final newState = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      return await repository.generateGroups(
        tournamentId: tournamentId,
        categoryId: categoryId,
        numberOfGroups: numberOfGroups,
        playersAdvancingPerGroup: playersAdvancingPerGroup,
        seedingMethod: seedingMethod,
      );
    });

    _safeSetState(newState);
  }

  /// Mueve un participante entre grupos.
  Future<void> moveParticipant({
    required String tournamentId,
    required String categoryId,
    required String participantId,
    required String fromGroupId,
    required String toGroupId,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final newState = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      return repository.moveParticipantBetweenGroups(
        tournamentId: tournamentId,
        categoryId: categoryId,
        participantId: participantId,
        fromGroupId: fromGroupId,
        toGroupId: toGroupId,
      );
    });

    _safeSetState(newState);

    // Si hubo error, lanzarlo para que el caller pueda manejarlo
    if (newState.hasError) {
      throw newState.error!;
    }
  }

  /// Intercambia dos participantes entre grupos.
  Future<void> swapParticipants({
    required String tournamentId,
    required String categoryId,
    required String participant1Id,
    required String group1Id,
    required String participant2Id,
    required String group2Id,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final newState = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      return repository.swapParticipantsBetweenGroups(
        tournamentId: tournamentId,
        categoryId: categoryId,
        participant1Id: participant1Id,
        group1Id: group1Id,
        participant2Id: participant2Id,
        group2Id: group2Id,
      );
    });

    _safeSetState(newState);

    // Si hubo error, lanzarlo para que el caller pueda manejarlo
    if (newState.hasError) {
      throw newState.error!;
    }
  }

  /// Bloquea los grupos y genera fixtures.
  Future<void> lockGroups({
    required String tournamentId,
    required String categoryId,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final newState = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      return await repository.lockGroupsAndGenerateFixtures(
        tournamentId: tournamentId,
        categoryId: categoryId,
      );
    });

    _safeSetState(newState);
  }

  /// Registra el resultado de un partido de grupo.
  Future<void> recordMatchResult({
    required String tournamentId,
    required String categoryId,
    required String matchId,
    required String winnerId,
    required String score,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final newState = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      return await repository.recordGroupMatchResult(
        tournamentId: tournamentId,
        categoryId: categoryId,
        matchId: matchId,
        winnerId: winnerId,
        score: score,
      );
    });

    _safeSetState(newState);
  }

  /// Avanza a la fase de eliminación directa.
  Future<void> advanceToKnockout({
    required String tournamentId,
    required String categoryId,
  }) async {
    final repository = ref.read(groupStageRepositoryProvider);
    await repository.advanceToKnockoutPhase(
      tournamentId: tournamentId,
      categoryId: categoryId,
    );

    // El refresco se manejará en la UI/Router
  }

  /// Elimina la fase de grupos (Solo Admin).
  Future<void> deleteGroupStage({
    required String tournamentId,
    required String categoryId,
  }) async {
    _safeSetState(const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      final repository = ref.read(groupStageRepositoryProvider);
      await repository.deleteGroupStage(
        tournamentId: tournamentId,
        categoryId: categoryId,
      );

      return null;
    });

    if (result.hasError) {
      _safeSetState(AsyncValue.error(result.error!, result.stackTrace!));
      if (_mounted) throw result.error!;
    } else {
      _safeSetState(const AsyncValue.data(null));
    }
  }
}
