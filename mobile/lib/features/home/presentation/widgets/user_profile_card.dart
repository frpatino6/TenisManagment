import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/domain/models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;

  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            // Avatar
            Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.onPrimaryContainer,
                      width: 2,
                    ),
                  ),
                  child: user.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            user.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                user.isProfessor
                                    ? Icons.sports_tennis
                                    : Icons.person,
                                size: 30,
                                color: colorScheme.onPrimary,
                              );
                            },
                          ),
                        )
                      : Icon(
                          user.isProfessor ? Icons.sports_tennis : Icons.person,
                          size: 30,
                          color: colorScheme.onPrimary,
                        ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const Gap(16),

            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideX(begin: 0.2, end: 0),

                  const Gap(4),

                  Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 
                            0.8,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideX(begin: 0.2, end: 0),

                  const Gap(8),

                  // Badge de rol
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: user.isProfessor
                              ? colorScheme.secondary
                              : colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isProfessor
                                  ? Icons.sports_tennis
                                  : Icons.school,
                              size: 16,
                              color: user.isProfessor
                                  ? colorScheme.onSecondary
                                  : colorScheme.onTertiary,
                            ),
                            const Gap(4),
                            Text(
                              user.isProfessor ? 'Profesor' : 'Estudiante',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: user.isProfessor
                                    ? colorScheme.onSecondary
                                    : colorScheme.onTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                      ),
                ],
              ),
            ),

            // Botón de editar perfil
            IconButton(
                  onPressed: () {
                    // TODO: Implementar edición de perfil
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edición de perfil próximamente'),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 
                      0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 800.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
          ],
        ),
      ),
    );
  }
}
