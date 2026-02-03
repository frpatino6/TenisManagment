import 'package:flutter/material.dart';
import '../../domain/models/user_ranking.dart';

class MyPositionBar extends StatelessWidget {
  final UserRanking? userRanking;

  const MyPositionBar({super.key, this.userRanking});

  @override
  Widget build(BuildContext context) {
    if (userRanking == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: const Border(
          top: BorderSide(color: Color(0xFFCCFF00), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tu posición: ${userRanking!.position}°',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Puntaje actual',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  userRanking!.score.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFFCCFF00),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
