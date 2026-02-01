import 'package:flutter/material.dart';

import '../../domain/models/group_stage_model.dart';

/// Resultado del diálogo de intercambio de jugadores.
class SwapPlayerResult {
  final String participant2Id;
  final String group2Id;

  const SwapPlayerResult({
    required this.participant2Id,
    required this.group2Id,
  });
}

/// Diálogo para seleccionar un jugador con quien intercambiar.
class SwapPlayerDialog extends StatelessWidget {
  final String currentPlayerId;
  final String currentGroupId;
  final List<GroupModel> otherGroups;

  const SwapPlayerDialog({
    super.key,
    required this.currentPlayerId,
    required this.currentGroupId,
    required this.otherGroups,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Intercambiar con...'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: otherGroups.length,
          itemBuilder: (context, groupIndex) {
            final group = otherGroups[groupIndex];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...group.standings.map((standing) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        standing.playerName?.substring(0, 1).toUpperCase() ??
                            '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      standing.playerName ?? 'Jugador ${standing.playerId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: standing.playerElo != null
                        ? Text(
                            'ELO: ${standing.playerElo!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.swap_horiz, size: 20),
                    onTap: () {
                      Navigator.of(context).pop(
                        SwapPlayerResult(
                          participant2Id: standing.playerId,
                          group2Id: group.id,
                        ),
                      );
                    },
                  );
                }),
                if (groupIndex < otherGroups.length - 1) const Divider(),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }
}
