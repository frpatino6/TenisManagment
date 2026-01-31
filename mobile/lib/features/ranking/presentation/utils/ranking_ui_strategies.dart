import 'package:flutter/material.dart';
import '../../domain/models/user_ranking.dart';

abstract class RankingPositionStrategy {
  const RankingPositionStrategy();
  Color getPositionColor(int position);
}

class StandardRankingPositionStrategy extends RankingPositionStrategy {
  const StandardRankingPositionStrategy();
  @override
  Color getPositionColor(int position) {
    if (position == 1) return const Color(0xFFFFD700);
    if (position == 2) return const Color(0xFFC0C0C0);
    if (position == 3) return const Color(0xFFCD7F32);
    return Colors.white70;
  }
}

abstract class RankingTrendStrategy {
  const RankingTrendStrategy();
  IconData getIcon(RankingTrend trend);
  Color getColor(RankingTrend trend);
}

class StandardRankingTrendStrategy extends RankingTrendStrategy {
  const StandardRankingTrendStrategy();
  @override
  IconData getIcon(RankingTrend trend) {
    switch (trend) {
      case RankingTrend.up:
        return Icons.arrow_upward;
      case RankingTrend.down:
        return Icons.arrow_downward;
      case RankingTrend.stable:
        return Icons.horizontal_rule;
    }
  }

  @override
  Color getColor(RankingTrend trend) {
    switch (trend) {
      case RankingTrend.up:
        return Colors.green;
      case RankingTrend.down:
        return Colors.red;
      case RankingTrend.stable:
        return Colors.grey;
    }
  }
}
