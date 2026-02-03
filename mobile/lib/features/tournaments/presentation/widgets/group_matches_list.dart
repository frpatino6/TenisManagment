import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/group_stage_model.dart';
import '../dialogs/group_match_result_dialog.dart';
import 'group_match_card.dart';

/// Widget que muestra la lista de partidos de grupos.
class GroupMatchesList extends ConsumerStatefulWidget {
  final List<GroupModel> groups;
  final bool isOrganizer;
  final String tournamentId;
  final String categoryId;

  const GroupMatchesList({
    super.key,
    required this.groups,
    required this.isOrganizer,
    required this.tournamentId,
    required this.categoryId,
  });

  @override
  ConsumerState<GroupMatchesList> createState() => _GroupMatchesListState();
}

class _GroupMatchesListState extends ConsumerState<GroupMatchesList> {
  int _selectedGroupIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const Center(child: Text('No hay grupos disponibles'));
    }

    final selectedGroup = widget.groups[_selectedGroupIndex];

    // Mapa de nombres de jugadores para este grupo
    final playerNames = {
      for (var standing in selectedGroup.standings)
        standing.playerId:
            standing.playerName ?? 'Jugador ${standing.playerId}',
    };

    return Column(
      children: [
        // Selector de grupo
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            value: _selectedGroupIndex,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Grupo',
              border: OutlineInputBorder(),
            ),
            items: widget.groups.asMap().entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGroupIndex = value;
                });
              }
            },
          ),
        ),

        // Lista de partidos
        Expanded(
          child: selectedGroup.matches.isEmpty
              ? const Center(
                  child: Text('No hay partidos generados para este grupo'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedGroup.matches.length,
                  itemBuilder: (context, index) {
                    final match = selectedGroup.matches[index];
                    return GroupMatchCard(
                      match: match,
                      playerNames: playerNames,
                      isOrganizer: widget.isOrganizer,
                      onRecordResult: widget.isOrganizer
                          ? (matchId) =>
                                _showRecordResultDialog(match, playerNames)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showRecordResultDialog(
    GroupStageMatchModel match,
    Map<String, String> playerNames,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => GroupMatchResultDialog(
        tournamentId: widget.tournamentId,
        categoryId: widget.categoryId,
        match: match,
        playerNames: playerNames,
      ),
    );
  }
}
