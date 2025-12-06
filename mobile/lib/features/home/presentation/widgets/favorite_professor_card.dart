import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../preferences/domain/models/user_preferences_model.dart';

/// Widget to display favorite professor card in home screen
class FavoriteProfessorCard extends ConsumerWidget {
  final FavoriteProfessor professor;

  const FavoriteProfessorCard({
    super.key,
    required this.professor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to professor schedules
          context.push('/professor/${professor.id}/schedules?name=${professor.name}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        professor.name.isNotEmpty
                            ? professor.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: colorScheme.error,
                              size: 18,
                            ),
                            const Gap(4),
                            Text(
                              'Profesor Favorito',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          professor.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (professor.specialties.isNotEmpty) ...[
                          const Gap(4),
                          Text(
                            professor.specialties.join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    onPressed: () {
                      context.push('/professor/${professor.id}/schedules?name=${professor.name}');
                    },
                  ),
                ],
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/professor/${professor.id}/schedules?name=${professor.name}');
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    'Ver horarios disponibles',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

