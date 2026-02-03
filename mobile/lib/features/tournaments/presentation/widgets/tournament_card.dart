import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tournament_model.dart';

/// Card que muestra información resumida de un torneo.
class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final bool isEnrolled;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.isEnrolled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(context),
                  if (isEnrolled) ...[
                    const SizedBox(width: 8),
                    _buildEnrolledBadge(context),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (tournament.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  tournament.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateRange(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${tournament.categories.length} ${tournament.categories.length == 1 ? 'categoría' : 'categorías'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrolledBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 14),
          SizedBox(width: 4),
          Text(
            'Ya inscrito',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (color, label) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo() {
    switch (tournament.status) {
      case TournamentStatus.draft:
        return (Colors.blue, 'Inscripciones');
      case TournamentStatus.inProgress:
        return (Colors.orange, 'En Curso');
      case TournamentStatus.completed:
        return (Colors.green, 'Finalizado');
      case TournamentStatus.cancelled:
        return (Colors.red, 'Cancelado');
    }
  }

  String _formatDateRange() {
    final formatter = DateFormat('d MMM', 'es');
    final start = formatter.format(tournament.startDate);
    final end = formatter.format(tournament.endDate);

    if (tournament.startDate.year != tournament.endDate.year) {
      final yearFormatter = DateFormat('d MMM yyyy', 'es');
      return '${yearFormatter.format(tournament.startDate)} - ${yearFormatter.format(tournament.endDate)}';
    }

    return '$start - $end';
  }
}
