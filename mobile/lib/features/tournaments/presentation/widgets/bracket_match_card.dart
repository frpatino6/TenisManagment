import 'package:flutter/material.dart';
import '../../domain/models/bracket_model.dart';

class BracketMatchCard extends StatelessWidget {
  final BracketMatchModel match;
  final double width;
  final double height;
  final bool isUserMatch;
  final VoidCallback? onTap;

  const BracketMatchCard({
    super.key,
    required this.match,
    this.width = 200,
    this.height = 100,
    this.isUserMatch = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUserMatch
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.1),
            width: isUserMatch ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerRow(
                context,
                name:
                    match.player1Name ??
                    (match.player1Id != null ? 'Jugador' : 'BYE'),
                score: match.score?.split('-').firstOrNull?.trim(),
                isWinner:
                    match.winnerId != null && match.winnerId == match.player1Id,
                isBye: match.player1Id == null,
              ),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.05),
                indent: 8,
                endIndent: 8,
              ),
              _buildPlayerRow(
                context,
                name:
                    match.player2Name ??
                    (match.player2Id != null ? 'Jugador' : 'BYE'),
                score: match.score?.split('-').lastOrNull?.trim(),
                isWinner:
                    match.winnerId != null && match.winnerId == match.player2Id,
                isBye: match.player2Id == null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context, {
    required String name,
    required String? score,
    required bool isWinner,
    required bool isBye,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: isWinner
              ? LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.1),
                    primaryColor.withValues(alpha: 0.01),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: Row(
          children: [
            if (isWinner)
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Text(
                isBye ? '$name (BYE)' : name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: isBye
                      ? theme.disabledColor
                      : (isWinner
                            ? primaryColor
                            : theme.textTheme.bodyMedium?.color),
                  fontStyle: isBye ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (score != null && score.isNotEmpty && !isBye && score != 'null')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isWinner
                      ? primaryColor.withValues(alpha: 0.1)
                      : theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  score,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner ? primaryColor : null,
                  ),
                ),
              ),
            if (isWinner && !isBye)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.stars_rounded, size: 14, color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}
