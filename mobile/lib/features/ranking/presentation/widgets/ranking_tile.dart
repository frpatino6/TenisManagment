import 'package:flutter/material.dart';
import '../../domain/models/user_ranking.dart';
import '../utils/ranking_ui_strategies.dart';
import '../../../matches/presentation/screens/report_match_screen.dart';

class RankingTile extends StatelessWidget {
  final UserRanking player;
  final RankingPositionStrategy positionStrategy;
  final RankingTrendStrategy trendStrategy;

  const RankingTile({
    super.key,
    required this.player,
    this.positionStrategy = const StandardRankingPositionStrategy(),
    this.trendStrategy = const StandardRankingTrendStrategy(),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: player.isCurrentUser
          ? const Color(0xFFCCFF00).withValues(alpha: 0.1)
          : const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: player.isCurrentUser
            ? const BorderSide(color: Color(0xFFCCFF00), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: player.isCurrentUser
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportMatchScreen(opponent: player),
                ),
              ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: SizedBox(
            width: 105,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    '${player.position}°',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: positionStrategy.getPositionColor(player.position),
                      fontSize: 15,
                    ),
                  ),
                ),
                _TrendIcon(trend: player.trend, strategy: trendStrategy),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: player.avatarUrl != null
                      ? NetworkImage(player.avatarUrl!)
                      : null,
                  onBackgroundImageError: player.avatarUrl != null
                      ? (exception, stackTrace) => {}
                      : null,
                  child: player.avatarUrl == null
                      ? Text(
                          player.name[0],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          title: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: player.isCurrentUser
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          trailing: Text(
            player.score.toInt().toString(),
            style: const TextStyle(
              color: Color(0xFFCCFF00),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  final RankingTrend trend;
  final RankingTrendStrategy strategy;

  const _TrendIcon({required this.trend, required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Icon(
      strategy.getIcon(trend),
      color: strategy.getColor(trend),
      size: 16,
    );
  }
}
