import 'package:flutter/material.dart';

import '../../domain/models/group_stage_model.dart';

/// Callback para mover un participante entre grupos.
typedef OnMoveParticipant =
    void Function(String participantId, String fromGroupId, String toGroupId);

/// Widget que muestra una card de un grupo con sus participantes.
class GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool showQualified;
  final VoidCallback? onTap;
  final bool isOrganizer;
  final GroupStageStatus? status;
  final List<GroupModel> otherGroups;
  final OnMoveParticipant? onMoveParticipant;

  const GroupCard({
    super.key,
    required this.group,
    this.showQualified = false,
    this.onTap,
    this.isOrganizer = false,
    this.status,
    this.otherGroups = const [],
    this.onMoveParticipant,
  });

  bool get _isEditMode => isOrganizer && status == GroupStageStatus.draft;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${group.participants.length} jugadores',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),
              ...group.standings.map((standing) {
                final isQualified =
                    showQualified && standing.qualifiedForKnockout;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isQualified
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: isQualified
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isQualified
                              ? Colors.green
                              : Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${standing.position + 1}',
                            style: TextStyle(
                              color: isQualified
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              standing.playerName ??
                                  'Jugador ${standing.playerId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${standing.wins}G ${standing.draws}E ${standing.losses}P',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${standing.points} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Sets: ${standing.setsWon}-${standing.setsLost}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (isQualified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ],
                      if (_isEditMode && otherGroups.isNotEmpty)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.compare_arrows),
                          tooltip: 'Mover a otro grupo',
                          onSelected: (toGroupId) {
                            onMoveParticipant?.call(
                              standing.playerId,
                              group.id,
                              toGroupId,
                            );
                          },
                          itemBuilder: (context) => otherGroups
                              .map(
                                (g) => PopupMenuItem(
                                  value: g.id,
                                  child: Text('Mover al ${g.name}'),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
