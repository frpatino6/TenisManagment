import 'package:flutter/material.dart';
import '../../domain/models/bracket_model.dart';
import 'bracket_match_card.dart';

class BracketTreeWidget extends StatelessWidget {
  final BracketModel bracket;
  final Function(BracketMatchModel)? onMatchTap;

  const BracketTreeWidget({super.key, required this.bracket, this.onMatchTap});

  @override
  Widget build(BuildContext context) {
    if (bracket.matches.isEmpty) {
      return const Center(child: Text('No hay partidos generados'));
    }

    final totalRounds = bracket.getTotalRounds();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(totalRounds, (index) {
          // El bracket visualmente: Ronda N -> ... -> Ronda 1 (Final)
          final roundNumber = totalRounds - index;
          return _buildRoundColumn(context, roundNumber, totalRounds);
        }),
      ),
    );
  }

  Widget _buildRoundColumn(BuildContext context, int round, int totalRounds) {
    final matches = bracket.getMatchesByRound(round);
    final theme = Theme.of(context);

    // Espaciado dinámico basado en la ronda
    final roundIndex = totalRounds - round;
    const double cardHeight = 100; // Updated to match new card height
    const double verticalGap = 32; // Base gap

    final double effectiveGap =
        (cardHeight + verticalGap) * (1 << roundIndex) - cardHeight;
    final double topOffset = roundIndex == 0
        ? 0
        : (cardHeight + verticalGap) * ((1 << roundIndex) - 1) / 2;

    return Padding(
      padding: const EdgeInsets.only(right: 64), // More space for lines
      child: Column(
        children: [
          // Round Header
          _buildRoundHeader(context, round, totalRounds),
          const SizedBox(height: 32),

          Column(
            children: [
              SizedBox(height: topOffset),
              ...matches.map((match) {
                return Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BracketMatchCard(
                          match: match,
                          onTap: onMatchTap != null
                              ? () => onMatchTap!(match)
                              : null,
                          width: 200,
                          height: 100,
                        ),
                        if (round > 1)
                          Positioned(
                            right: -64,
                            top: cardHeight / 2,
                            child: CustomPaint(
                              size: Size(64, effectiveGap + cardHeight),
                              painter: BracketLinePainter(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.3,
                                ),
                                connectionType: _getConnectionType(
                                  match,
                                  matches,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: effectiveGap),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundHeader(BuildContext context, int round, int totalRounds) {
    final String label = _getRoundLabel(round);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  String _getRoundLabel(int round) {
    switch (round) {
      case 1:
        return 'Final';
      case 2:
        return 'Semifinales';
      case 3:
        return 'Cuartos';
      case 4:
        return 'Octavos';
      default:
        return 'Ronda $round';
    }
  }

  int _getConnectionType(
    BracketMatchModel match,
    List<BracketMatchModel> roundMatches,
  ) {
    final index = roundMatches.indexOf(match);
    return index % 2 == 0 ? 0 : 1;
  }
}

class BracketLinePainter extends CustomPainter {
  final Color color;
  final int connectionType;

  BracketLinePainter({required this.color, required this.connectionType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (connectionType == 0) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width / 2, size.height / 2);
      path.lineTo(size.width, size.height / 2);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width / 2, -size.height / 2);
      path.lineTo(size.width, -size.height / 2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
