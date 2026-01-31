import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/dtos/create_tournament_dto.dart';

import '../../../../core/services/http_client.dart';
import '../../data/tournament_repository_impl.dart';
import '../../domain/models/bracket_model.dart';
import '../../domain/models/tournament_model.dart';
import '../../domain/repositories/tournament_repository.dart';

part 'tournaments_provider.g.dart';

/// Provider del repositorio de torneos.
@riverpod
TournamentRepository tournamentRepository(Ref ref) {
  // Repository con cliente HTTP real
  return TournamentRepositoryImpl(ref.read(appHttpClientProvider));
}

/// Provider para la lista de torneos.
@riverpod
class Tournaments extends _$Tournaments {
  @override
  Future<List<TournamentModel>> build() async {
    final repository = ref.watch(tournamentRepositoryProvider);
    return repository.getTournaments();
  }

  /// Refresca la lista de torneos.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      return repository.getTournaments();
    });
  }

  /// Crea un nuevo torneo.
  Future<void> create(CreateTournamentDto dto) async {
    final repository = ref.read(tournamentRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createTournament(dto);
      return repository.getTournaments();
    });
  }
}

/// Provider para un torneo específico.
@riverpod
class TournamentDetail extends _$TournamentDetail {
  @override
  Future<TournamentModel> build(String tournamentId) async {
    final repository = ref.watch(tournamentRepositoryProvider);
    return repository.getTournamentById(tournamentId);
  }

  /// Refresca los datos del torneo.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      return repository.getTournamentById(tournamentId);
    });
  }

  /// Inscribe al usuario en una categoría.
  Future<void> enrollInCategory(String categoryId) async {
    final repository = ref.read(tournamentRepositoryProvider);
    await repository.enrollInCategory(tournamentId, categoryId);

    // Refrescar el torneo después de inscribirse
    await refresh();
  }

  /// Genera el bracket para una categoría.
  Future<void> generateBracket(String categoryId) async {
    final repository = ref.read(tournamentRepositoryProvider);
    await repository.generateBracket(tournamentId, categoryId);

    // Refrescar el torneo para actualizar su estado
    await refresh();
  }
}

/// Provider para el bracket de una categoría.
@riverpod
class Bracket extends _$Bracket {
  @override
  Future<BracketModel?> build(String tournamentId, String categoryId) async {
    final repository = ref.watch(tournamentRepositoryProvider);
    return repository.getBracket(tournamentId, categoryId);
  }

  /// Refresca el bracket.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      return repository.getBracket(tournamentId, categoryId);
    });
  }

  /// Registra el resultado de un partido.
  Future<void> recordMatchResult({
    required String matchId,
    required String winnerId,
    required String score,
  }) async {
    final repository = ref.read(tournamentRepositoryProvider);
    state = await AsyncValue.guard(() async {
      return repository.recordMatchResult(
        tournamentId: tournamentId,
        matchId: matchId,
        winnerId: winnerId,
        score: score,
      );
    });
  }
}
