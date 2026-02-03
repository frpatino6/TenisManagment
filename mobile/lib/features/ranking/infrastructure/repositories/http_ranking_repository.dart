import 'dart:convert';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/user_ranking.dart';
import '../../domain/repositories/ranking_repository.dart';

class HttpRankingRepository implements RankingRepository {
  final AppHttpClient _httpClient;
  final UserModel? _currentUser;

  HttpRankingRepository(this._httpClient, this._currentUser);

  @override
  Future<List<UserRanking>> getEloRankings() async {
    final response = await _httpClient.get(
      Uri.parse('${AppConfig.apiBaseUrl}/ranking/elo'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final currentUserId = _currentUser?.id ?? '';
      return data
          .map(
            (item) => UserRanking.fromBackendJson(
              item,
              currentUserId: currentUserId,
              isRace: false,
            ),
          )
          .toList();
    } else {
      throw Exception('Error al obtener ranking ELO: ${response.statusCode}');
    }
  }

  @override
  Future<List<UserRanking>> getRaceRankings() async {
    final response = await _httpClient.get(
      Uri.parse('${AppConfig.apiBaseUrl}/ranking/race'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final currentUserId = _currentUser?.id ?? '';
      return data
          .map(
            (item) => UserRanking.fromBackendJson(
              item,
              currentUserId: currentUserId,
              isRace: true,
            ),
          )
          .toList();
    } else {
      throw Exception('Error al obtener ranking Race: ${response.statusCode}');
    }
  }
}
