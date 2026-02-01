import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/tournament_model.dart';

/// Card que muestra información de una categoría de torneo.
class CategoryCard extends ConsumerWidget {
  final TournamentCategoryModel category;
  final String tournamentId;
  final TournamentStatus tournamentStatus;
  final VoidCallback onEnroll;
  final VoidCallback onViewBracket;
  final VoidCallback? onGenerateBracket;
  final VoidCallback? onConfigureGroups;
  final VoidCallback? onViewGroups;

  const CategoryCard({
    super.key,
    required this.category,
    required this.tournamentId,
    required this.tournamentStatus,
    required this.onEnroll,
    required this.onViewBracket,
    this.onGenerateBracket,
    this.onConfigureGroups,
    this.onViewGroups,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isEnrolled =
        currentUser != null && category.isUserEnrolled(currentUser.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildGenderIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getGenderLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 4, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            category.format == TournamentFormat.hybrid
                                ? 'Híbrido'
                                : 'Eliminación Simple',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildParticipantsBadge(),
              ],
            ),
            const SizedBox(height: 12),
            if (category.championId != null) ...[
              _buildChampionInfo(context),
              const SizedBox(height: 12),
            ],
            if (category.format == TournamentFormat.hybrid &&
                category.groupStageConfig != null) ...[
              _buildConfigSummary(theme: Theme.of(context)),
              const SizedBox(height: 12),
            ],

            // Botones de acción
            _buildActionButtons(context, ref, currentUser, isEnrolled),
          ],
        ),
      ),
    );
  }

  Widget _buildChampionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Torneo Finalizado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      '¡Felicidades al Campeón!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    bool isEnrolled,
  ) {
    final isAdmin = currentUser?.isTenantAdmin ?? false;
    final isHybrid = category.format == TournamentFormat.hybrid;
    final hasGroups = category.groupStageConfig != null;

    // Para torneos híbridos, mostrar botones de grupos
    if (isHybrid) {
      return Column(
        children: [
          // Fila 1: Inscripción o estado
          Row(
            children: [
              if (isEnrolled && !isAdmin) Expanded(child: _buildEnrolledChip()),
              if (tournamentStatus == TournamentStatus.draft &&
                  !isEnrolled &&
                  !isAdmin)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEnroll,
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: const Text('Inscribirme'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),

          if (isAdmin) const SizedBox(height: 8),

          // Fila 2: Botones de grupos (solo admin)
          if (isAdmin)
            Row(
              children: [
                // Configurar grupos (si no se ha generado la fase de grupos)
                // Usamos una lógica más robusta: Mostrar Configurar si hay callback
                // y NO mostrar Ver Grupos si NO hay callback de Ver Grupos
                if (onConfigureGroups != null &&
                    (!category.hasGroupStage || onViewGroups == null))
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfigureGroups,
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Configurar Grupos'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),

                // Ver grupos (si ya se generó la fase de grupos)
                if (category.hasGroupStage && onViewGroups != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewGroups,
                      icon: const Icon(Icons.groups, size: 18),
                      label: const Text('Ver Grupos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (hasGroups && category.hasBracket) const SizedBox(width: 8),

                // Ver bracket (si existe)
                if (category.hasBracket)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewBracket,
                      icon: const Icon(Icons.account_tree, size: 18),
                      label: const Text('Ver Bracket'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    }

    // Para torneos no híbridos, mostrar botones originales
    return Row(
      children: [
        if (isEnrolled && !isAdmin) ...[
          Expanded(child: _buildEnrolledChip()),
          const SizedBox(width: 8),
        ],
        if (tournamentStatus == TournamentStatus.draft &&
            !isEnrolled &&
            !isAdmin)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEnroll,
              icon: const Icon(Icons.how_to_reg, size: 18),
              label: const Text('Inscribirme'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if ((tournamentStatus == TournamentStatus.draft ||
                tournamentStatus == TournamentStatus.inProgress) &&
            isAdmin &&
            !category.hasBracket &&
            onGenerateBracket != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onGenerateBracket,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Generar Bracket'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        if (category.hasBracket || tournamentStatus != TournamentStatus.draft)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onViewBracket,
              icon: const Icon(Icons.account_tree, size: 18),
              label: const Text('Ver Bracket'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderIcon() {
    final (icon, color) = _getGenderIconData();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  (IconData, Color) _getGenderIconData() {
    switch (category.gender) {
      case CategoryGender.male:
        return (Icons.male, Colors.blue);
      case CategoryGender.female:
        return (Icons.female, Colors.pink);
      case CategoryGender.mixed:
        return (Icons.people, Colors.purple);
    }
  }

  String _getGenderLabel() {
    switch (category.gender) {
      case CategoryGender.male:
        return 'Masculino';
      case CategoryGender.female:
        return 'Femenino';
      case CategoryGender.mixed:
        return 'Mixto';
    }
  }

  Widget _buildParticipantsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            '${category.participants.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSummary({required ThemeData theme}) {
    final config = category.groupStageConfig!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildConfigItem(
                Icons.grid_view,
                'Grupos',
                '${config.numberOfGroups}',
              ),
              _buildConfigItem(
                Icons.trending_up,
                'Clasifican',
                '${config.playersAdvancingPerGroup}',
              ),
              _buildConfigItem(
                Icons.shuffle,
                'Sorteo',
                config.seedingMethod == SeedingMethod.random
                    ? 'Azar'
                    : 'Ranking',
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Puntos: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'PG: ${config.pointsForWin} | PE: ${config.pointsForDraw} | PP: ${config.pointsForLoss}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEnrolledChip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green),
          SizedBox(width: 6),
          Text(
            'Inscrito',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
