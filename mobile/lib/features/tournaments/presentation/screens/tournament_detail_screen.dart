import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/tournaments_provider.dart';
import '../widgets/category_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/tournament_model.dart';

/// Pantalla que muestra el detalle de un torneo específico.
class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Torneo'),
        actions: [
          if (ref.watch(currentUserProvider)?.isTenantAdmin ?? false)
            tournamentAsync.when(
              data: (tournament) => IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await context.push(
                    '/tournaments/${tournament.id}/edit',
                    extra: tournament,
                  );
                  // Refrescar al volver
                  if (context.mounted) {
                    ref
                        .read(tournamentDetailProvider(tournamentId).notifier)
                        .refresh();
                  }
                },
                tooltip: 'Editar Torneo',
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(tournamentDetailProvider(tournamentId).notifier)
                  .refresh();
            },
          ),
        ],
      ),
      body: tournamentAsync.when(
        data: (tournament) => _buildContent(context, ref, tournament),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorState(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(tournamentDetailProvider(tournamentId).notifier)
            .refresh();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, tournament),
            const SizedBox(height: 24),
            _buildInfoSection(tournament),
            const SizedBox(height: 24),
            _buildCategoriesSection(context, ref, tournament),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatusChip(tournament.status),
                          if (!(ref.watch(currentUserProvider)?.isTenantAdmin ??
                                  false) &&
                              tournament.isUserEnrolled(
                                ref.watch(currentUserProvider)?.id ?? '',
                              ))
                            _buildEnrolledChip(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tournament.description != null) ...[
              const SizedBox(height: 16),
              Text(
                tournament.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledChip() {
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
            'Inscrito',
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

  Widget _buildStatusChip(TournamentStatus status) {
    final (color, label, icon) = _getStatusInfo(status);

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
    );
  }

  (Color, String, IconData) _getStatusInfo(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return (Colors.blue, 'Inscripciones Abiertas', Icons.how_to_reg);
      case TournamentStatus.inProgress:
        return (Colors.orange, 'En Curso', Icons.sports_tennis);
      case TournamentStatus.completed:
        return (Colors.green, 'Finalizado', Icons.check_circle);
      case TournamentStatus.cancelled:
        return (Colors.red, 'Cancelado', Icons.cancel);
    }
  }

  Widget _buildInfoSection(TournamentModel tournament) {
    final dateFormatter = DateFormat('EEEE, d MMMM yyyy', 'es');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Inicio',
              dateFormatter.format(tournament.startDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.event,
              'Fin',
              dateFormatter.format(tournament.endDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.category,
              'Categorías',
              '${tournament.categories.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...tournament.categories.map((category) {
          return CategoryCard(
            category: category,
            tournamentId: tournamentId,
            tournamentStatus: tournament.status,
            onEnroll: () => _handleEnroll(context, ref, category.id!),
            onViewBracket: () {
              context.push('/tournaments/$tournamentId/bracket/${category.id}');
            },
            onGenerateBracket: category.id != null
                ? () {
                    _handleGenerateBracket(context, ref, category.id!);
                  }
                : null,
            onConfigureGroups: category.id != null
                ? () {
                    context.push(
                      '/tournaments/$tournamentId/categories/${category.id}/groups/config',
                      extra: {
                        'totalParticipants': category.participants.length,
                      },
                    );
                  }
                : null,
            onViewGroups: category.id != null
                ? () {
                    context.push(
                      '/tournaments/$tournamentId/categories/${category.id}/groups',
                      extra: {
                        'isOrganizer':
                            ref.read(currentUserProvider)?.isTenantAdmin ??
                            false,
                      },
                    );
                  }
                : null,
          );
        }),
      ],
    );
  }

  Future<void> _handleEnroll(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Procesando inscripción...')),
      );

      await ref
          .read(tournamentDetailProvider(tournamentId).notifier)
          .enrollInCategory(categoryId);

      if (context.mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('¡Inscripción exitosa!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el torneo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(tournamentDetailProvider(tournamentId).notifier)
                    .refresh();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerateBracket(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generando bracket...')),
      );

      await ref
          .read(tournamentDetailProvider(tournamentId).notifier)
          .generateBracket(categoryId);

      if (context.mounted) {
        scaffoldMessenger.clearSnackBars();
        context.push('/tournaments/$tournamentId/bracket/$categoryId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar bracket: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
