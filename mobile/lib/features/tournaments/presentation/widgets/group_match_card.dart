import 'package:flutter/material.dart';

import '../../domain/models/group_stage_model.dart';

/// Widget que muestra una card de un partido de grupo con estilo competitivo.
class GroupMatchCard extends StatelessWidget {
  final GroupStageMatchModel match;
  final bool isOrganizer;
  final Map<String, String> playerNames;
  final Function(String matchId)? onRecordResult;

  const GroupMatchCard({
    super.key,
    required this.match,
    required this.playerNames,
    this.isOrganizer = false,
    this.onRecordResult,
  });

  bool get _isCompleted => match.winnerId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        boxShadow: [
          BoxShadow(
            color: _isCompleted
                ? primaryColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: _isCompleted ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isCompleted
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
          width: _isCompleted ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isOrganizer && !_isCompleted && onRecordResult != null)
              ? () => onRecordResult!(match.id)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header con estado del partido
                _buildMatchHeader(context, theme, primaryColor),
                const SizedBox(height: 20),

                // Jugadores enfrentados
                _buildPlayersSection(context, theme, primaryColor, isDark),

                // Acción o resultado
                const SizedBox(height: 16),
                _buildActionSection(context, theme, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isCompleted
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isCompleted
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCompleted ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: _isCompleted ? primaryColor : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                _isCompleted ? 'FINALIZADO' : 'PENDIENTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _isCompleted ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (_isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              match.score ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayersSection(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    bool isDark,
  ) {
    final player1Name = playerNames[match.player1Id] ?? 'Jugador 1';
    final player2Name = playerNames[match.player2Id] ?? 'Jugador 2';
    final player1IsWinner = match.winnerId == match.player1Id;
    final player2IsWinner = match.winnerId == match.player2Id;

    return Row(
      children: [
        // Jugador 1
        Expanded(
          child: _buildPlayerCard(
            context,
            player1Name,
            player1IsWinner,
            primaryColor,
            isDark,
            true,
          ),
        ),

        // VS Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.2),
                      primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Jugador 2
        Expanded(
          child: _buildPlayerCard(
            context,
            player2Name,
            player2IsWinner,
            primaryColor,
            isDark,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    String playerName,
    bool isWinner,
    Color primaryColor,
    bool isDark,
    bool isLeft,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: isWinner
            ? LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  primaryColor.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isWinner ? null : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (isWinner) ...[
            Icon(
              Icons.emoji_events,
              color: primaryColor,
              size: 24,
              shadows: [
                Shadow(
                  color: primaryColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            playerName,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
              fontSize: isWinner ? 15 : 14,
              color: isWinner ? primaryColor : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isWinner) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'GANADOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    if (_isCompleted) {
      return const SizedBox.shrink();
    }

    if (isOrganizer && onRecordResult != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              primaryColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis, color: primaryColor, size: 20),
            const SizedBox(width: 10),
            Text(
              'REGISTRAR RESULTADO',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: primaryColor, size: 18),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Esperando resultado',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
