import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/http_client.dart';
import '../../domain/repositories/match_repository.dart';
import '../../infrastructure/repositories/http_match_repository.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

part 'match_providers.g.dart';

@riverpod
MatchRepository matchRepository(Ref ref) {
  final httpClient = ref.watch(appHttpClientProvider);
  final currentUser = ref.watch(currentUserProvider);
  return HttpMatchRepository(httpClient, currentUser);
}

@riverpod
class RecordMatchAction extends _$RecordMatchAction {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> execute({
    required String winnerId,
    required String loserId,
    required String score,
    bool isTournament = false,
    bool isOffPeak = false,
    bool isMatchmakingChallenge = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(matchRepositoryProvider)
          .recordMatchResult(
            winnerId: winnerId,
            loserId: loserId,
            score: score,
            isTournament: isTournament,
            isOffPeak: isOffPeak,
            isMatchmakingChallenge: isMatchmakingChallenge,
          );
    });
  }
}
