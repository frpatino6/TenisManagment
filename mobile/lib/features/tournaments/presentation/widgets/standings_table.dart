import 'package:flutter/material.dart';

import '../../domain/models/group_stage_model.dart';

/// Widget que muestra una tabla de clasificación.
class StandingsTable extends StatelessWidget {
  final List<GroupStandingModel> standings;
  final int qualifiedCount;

  const StandingsTable({
    super.key,
    required this.standings,
    this.qualifiedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        ),
        columns: const [
          DataColumn(
            label: Text('Pos', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Jugador',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('PJ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('G', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('E', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Sets', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Games', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: standings.asMap().entries.map((entry) {
          final index = entry.key;
          final standing = entry.value;
          final isQualified = index < qualifiedCount;

          return DataRow(
            color: WidgetStateProperty.all(
              isQualified ? Colors.green.withOpacity(0.1) : null,
            ),
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${standing.position + 1}',
                      style: TextStyle(
                        fontWeight: isQualified ? FontWeight.bold : null,
                      ),
                    ),
                    if (isQualified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              DataCell(
                Text(
                  standing.playerName ?? 'Jugador ${standing.playerId}',
                  style: TextStyle(
                    fontWeight: isQualified ? FontWeight.bold : null,
                  ),
                ),
              ),
              DataCell(Text('${standing.matchesPlayed}')),
              DataCell(Text('${standing.wins}')),
              DataCell(Text('${standing.draws}')),
              DataCell(Text('${standing.losses}')),
              DataCell(
                Text(
                  '${standing.points}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  '${standing.setsWon}-${standing.setsLost} (${standing.setDifference >= 0 ? '+' : ''}${standing.setDifference})',
                ),
              ),
              DataCell(
                Text(
                  '${standing.gamesWon}-${standing.gamesLost} (${standing.gameDifference >= 0 ? '+' : ''}${standing.gameDifference})',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
