import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/models/tenant_professor_model.dart';
import 'edit_professor_sheet.dart';

class ProfessorProfileTab extends ConsumerWidget {
  final TenantProfessorModel professor;

  const ProfessorProfileTab({super.key, required this.professor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = professor.name.isNotEmpty
        ? professor.name
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
              .toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: professor.isActive
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: professor.isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Gap(24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professor.name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: professor.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: professor.isActive
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          professor.isActive ? 'Activo' : 'Inactivo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: professor.isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Contact Info
          _buildsectionHeader(context, 'Información de Contacto'),
          const Gap(16),
          _buildInfoTile(
            context,
            icon: Icons.email_outlined,
            label: 'Correo Electrónico',
            value: professor.email,
          ),
          if (professor.phone != null) ...[
            const Gap(12),
            _buildInfoTile(
              context,
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: professor.phone!,
            ),
          ],

          const Gap(24),

          // Professional Info
          _buildsectionHeader(context, 'Información Profesional'),
          const Gap(16),
          _buildInfoTile(
            context,
            icon: Icons.attach_money,
            label: 'Tarifa por Hora',
            value: CurrencyUtils.format(professor.hourlyRate),
          ),
          const Gap(12),
          _buildInfoTile(
            context,
            icon: Icons.work_outline,
            label: 'Experiencia',
            value: '${professor.experienceYears} años',
          ),

          const Gap(24),

          // Specialties
          _buildsectionHeader(context, 'Especialidades'),
          const Gap(16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: professor.specialties.map((specialty) {
              return Chip(
                label: Text(
                  specialty,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),

          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      EditProfessorSheet(professor: professor),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildsectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
