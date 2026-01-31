import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/group_stage_model.dart';
import '../providers/group_stage_provider.dart';
import '../providers/tournaments_provider.dart';
import '../widgets/group_card.dart';
import '../widgets/group_matches_list.dart';
import '../widgets/standings_table.dart';

/// Pantalla para visualizar la fase de grupos de un torneo.
///
/// Muestra 3 tabs:
/// - Grupos: Vista de grupos con participantes
/// - Partidos: Fixtures por grupo
/// - Clasificación: Tabla de posiciones
class GroupStageViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String categoryId;
  final bool isOrganizer;

  const GroupStageViewScreen({
    super.key,
    required this.tournamentId,
    required this.categoryId,
    this.isOrganizer = false,
  });

  @override
  ConsumerState<GroupStageViewScreen> createState() =>
      _GroupStageViewScreenState();
}

class _GroupStageViewScreenState extends ConsumerState<GroupStageViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupStageAsync = ref.watch(
      groupStageProvider(
        tournamentId: widget.tournamentId,
        categoryId: widget.categoryId,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fase de Grupos'),
        actions: [
          if (widget.isOrganizer)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Reiniciar Fase de Grupos',
              onPressed: _handleResetGroups,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(
                groupStageProvider(
                  tournamentId: widget.tournamentId,
                  categoryId: widget.categoryId,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Grupos'),
            Tab(icon: Icon(Icons.sports_tennis), text: 'Partidos'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Clasificación'),
          ],
        ),
      ),
      body: groupStageAsync.when(
        data: (groupStage) {
          if (groupStage == null) {
            return const Center(
              child: Text('No se ha generado la fase de grupos'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGroupsTab(groupStage),
              _buildMatchesTab(groupStage),
              _buildStandingsTab(groupStage),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(groupStageProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: groupStageAsync.maybeWhen(
        data: (groupStage) {
          if (groupStage != null &&
              groupStage.status == GroupStageStatus.draft &&
              widget.isOrganizer) {
            return FloatingActionButton.extended(
              onPressed: _confirmLockGroups,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Confirmar Grupos'),
              backgroundColor: Theme.of(context).primaryColor,
            );
          }
          return null;
        },
        orElse: () => null,
      ),
    );
  }

  Future<void> _confirmLockGroups() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Confirmar Grupos?'),
        content: const Text(
          'Una vez confirmados, no podrás mover jugadores entre grupos y se generarán todos los partidos automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar y Generar Partidos'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        final generator = ref.read(groupStageGeneratorProvider.notifier);
        await generator.lockGroups(
          tournamentId: widget.tournamentId,
          categoryId: widget.categoryId,
        );

        if (!mounted) return;

        // Refrescar para actualizar la vista inmediatamente
        // ignore: unused_result
        ref.refresh(
          groupStageProvider(
            tournamentId: widget.tournamentId,
            categoryId: widget.categoryId,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupos confirmados y partidos generados con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar grupos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGroupsTab(GroupStageModel groupStage) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupStage.groups.length,
      itemBuilder: (context, index) {
        final group = groupStage.groups[index];
        final otherGroups = groupStage.groups
            .where((g) => g.id != group.id)
            .toList();

        return GroupCard(
          group: group,
          status: groupStage.status,
          isOrganizer: widget.isOrganizer,
          otherGroups: otherGroups,
          showQualified: groupStage.status == GroupStageStatus.completed,
          onMoveParticipant: (participantId, fromGroupId, toGroupId) =>
              _handleMoveParticipant(participantId, fromGroupId, toGroupId),
          onTap: () {
            // Navegar a detalles del grupo si es necesario
          },
        );
      },
    );
  }

  Future<void> _handleMoveParticipant(
    String participantId,
    String fromGroupId,
    String toGroupId,
  ) async {
    if (!mounted) return;
    try {
      final generator = ref.read(groupStageGeneratorProvider.notifier);
      await generator.moveParticipant(
        tournamentId: widget.tournamentId,
        categoryId: widget.categoryId,
        participantId: participantId,
        fromGroupId: fromGroupId,
        toGroupId: toGroupId,
      );

      if (!mounted) return;

      // Refrescar para actualizar la vista inmediatamente
      // ignore: unused_result
      ref.refresh(
        groupStageProvider(
          tournamentId: widget.tournamentId,
          categoryId: widget.categoryId,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Participante movido con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al mover participante: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMatchesTab(GroupStageModel groupStage) {
    return GroupMatchesList(
      groups: groupStage.groups,
      isOrganizer: widget.isOrganizer,
      tournamentId: widget.tournamentId,
      categoryId: widget.categoryId,
    );
  }

  Widget _buildStandingsTab(GroupStageModel groupStage) {
    // Consolidar todas las clasificaciones de todos los grupos
    final allStandings =
        groupStage.groups.expand((group) => group.standings).toList()
          ..sort((a, b) => b.points.compareTo(a.points));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clasificación General',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          StandingsTable(
            standings: allStandings,
            qualifiedCount: groupStage.groups.first.standings
                .where((s) => s.qualifiedForKnockout)
                .length,
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetGroups() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar Fase de Grupos?'),
        content: const Text(
          'Esta acción eliminará todos los grupos y partidos de esta categoría. '
          'Solo podrás hacerlo si no hay resultados registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REINICIAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      // Mostrar loading de pantalla completa
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reiniciando fase de grupos...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await ref
            .read(groupStageGeneratorProvider.notifier)
            .deleteGroupStage(
              tournamentId: widget.tournamentId,
              categoryId: widget.categoryId,
            );

        if (mounted) {
          // Invalidar el provider del torneo para que se refresque al volver
          ref.invalidate(tournamentDetailProvider(widget.tournamentId));

          // Cerrar loading primero usando el navegador raíz (donde vive el diálogo)
          Navigator.of(context, rootNavigator: true).pop();

          // Esperar un frame para asegurar que el diálogo se cerró
          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fase de grupos reiniciada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            // Volver a la pantalla anterior indicando que hubo cambios
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          // Cerrar loading usando navegador raíz
          Navigator.of(context, rootNavigator: true).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
