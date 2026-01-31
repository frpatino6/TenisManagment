import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/match_model.dart';
import '../../domain/repositories/match_repository.dart';

class HttpMatchRepository implements MatchRepository {
  final AppHttpClient _httpClient;
  final UserModel? _currentUser;

  HttpMatchRepository(this._httpClient, this._currentUser);

  @override
  Future<void> recordMatchResult({
    required String winnerId,
    required String loserId,
    required String score,
    bool isTournament = false,
    bool isOffPeak = false,
    bool isMatchmakingChallenge = false,
  }) async {
    final currentUserId = _currentUser?.id ?? '';

    final response = await _httpClient.post(
      Uri.parse('${AppConfig.apiBaseUrl}/matches'),
      body: {
        'winnerId': winnerId == 'CURRENT_USER' ? currentUserId : winnerId,
        'loserId': loserId == 'CURRENT_USER' ? currentUserId : loserId,
        'score': score,
        'isTournament': isTournament,
        'isOffPeak': isOffPeak,
        'isMatchmakingChallenge': isMatchmakingChallenge,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar resultado: ${response.statusCode}');
    }
  }

  @override
  Future<List<MatchModel>> getRecentMatches() async {
    // Implementaremos esto si necesitamos mostrar historial en mobile
    return [];
  }
}
