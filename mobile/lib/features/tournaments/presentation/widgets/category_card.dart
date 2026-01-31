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

  const CategoryCard({
    super.key,
    required this.category,
    required this.tournamentId,
    required this.tournamentStatus,
    required this.onEnroll,
    required this.onViewBracket,
    this.onGenerateBracket,
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
                      Text(
                        _getGenderLabel(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildParticipantsBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isEnrolled) Expanded(child: _buildEnrolledChip()),
                if (isEnrolled) const SizedBox(width: 8),
                if (tournamentStatus == TournamentStatus.draft &&
                    !isEnrolled &&
                    !(currentUser?.isTenantAdmin ?? false))
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
                    (currentUser?.isTenantAdmin ?? false) &&
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
                if (category.hasBracket ||
                    tournamentStatus != TournamentStatus.draft)
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
        ),
      ),
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
