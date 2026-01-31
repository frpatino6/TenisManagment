import 'package:flutter/material.dart';
import '../../domain/models/user_ranking.dart';

class RankingPodium extends StatelessWidget {
  final List<UserRanking> topPlayers;

  const RankingPodium({super.key, required this.topPlayers});

  @override
  Widget build(BuildContext context) {
    if (topPlayers.isEmpty) return const SizedBox.shrink();

    // Organizar por posición (1, 2, 3) -> Visualmente (2, 1, 3)
    final first = topPlayers.firstWhere(
      (p) => p.position == 1,
      orElse: () => topPlayers[0],
    );
    final second = topPlayers.firstWhere(
      (p) => p.position == 2,
      orElse: () => topPlayers.length > 1 ? topPlayers[1] : first,
    );
    final third = topPlayers.firstWhere(
      (p) => p.position == 3,
      orElse: () => topPlayers.length > 2 ? topPlayers[2] : first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Segundo Lugar
          if (topPlayers.length > 1)
            _PodiumItem(
              player: second,
              avatarSize: 70,
              medalColor: const Color(0xFFC0C0C0), // Plata
              position: 2,
            ),

          // Primer Lugar (Más grande y al centro)
          _PodiumItem(
            player: first,
            avatarSize: 90,
            medalColor: const Color(0xFFFFD700), // Oro
            position: 1,
            isFirst: true,
          ),

          // Tercer Lugar
          if (topPlayers.length > 2)
            _PodiumItem(
              player: third,
              avatarSize: 60,
              medalColor: const Color(0xFFCD7F32), // Bronce
              position: 3,
            ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final UserRanking player;
  final double avatarSize;
  final Color medalColor;
  final int position;
  final bool isFirst;

  const _PodiumItem({
    required this.player,
    required this.avatarSize,
    required this.medalColor,
    required this.position,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    // Usar solo el primer nombre en el podio por espacio
    final firstName = player.name.split(' ')[0];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFirst ? const Color(0xFFCCFF00) : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.grey[800],
                backgroundImage: player.avatarUrl != null
                    ? NetworkImage(player.avatarUrl!)
                    : null,
                onBackgroundImageError: player.avatarUrl != null
                    ? (exception, stackTrace) =>
                          {} // Silenciar errores en tests
                    : null,
                child: player.avatarUrl == null
                    ? Text(
                        player.name[0],
                        style: TextStyle(
                          fontSize: avatarSize * 0.4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black45, width: 1),
                ),
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: -15,
                child: Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          firstName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          player.formattedScore,
          style: TextStyle(
            color: const Color(0xFFCCFF00),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
