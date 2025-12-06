import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../preferences/domain/models/user_preferences_model.dart';

/// Widget to display favorite tenant (center) card in home screen
class FavoriteTenantCard extends ConsumerWidget {
  final FavoriteTenant tenant;

  const FavoriteTenantCard({
    super.key,
    required this.tenant,
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
          // Navigate to tenant details or booking
          context.push('/book-class');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondaryContainer,
                colorScheme.secondaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (tenant.logo != null && tenant.logo!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    tenant.logo!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(colorScheme);
                    },
                  ),
                )
              else
                _buildDefaultIcon(colorScheme),
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
                          'Centro Favorito',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      tenant.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      tenant.slug,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                onPressed: () {
                  context.push('/book-class');
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDefaultIcon(ColorScheme colorScheme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.secondary.withValues(alpha: 0.2),
      ),
      child: Icon(
        Icons.business,
        color: colorScheme.secondary,
        size: 32,
      ),
    );
  }
}

