import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/professor_provider.dart';

class StudentsListWidget extends ConsumerWidget {
  const StudentsListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentsAsync = ref.watch(professorStudentsProvider);

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const Gap(16),
                  Text(
                    'No tienes estudiantes aún',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      right: index < students.length - 1 ? 12 : 0,
                    ),
                    child: _buildStudentCard(context, student),
                  )
                  .animate()
                  .slideX(
                    duration: 600.ms,
                    curve: Curves.easeOut,
                    delay: (index * 100).ms,
                  )
                  .fadeIn(duration: 400.ms, delay: (index * 100).ms);
            },
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            'Error al cargar estudiantes: $error',
            style: GoogleFonts.inter(color: colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, student) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar y nombre
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      student.level,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(16),

          // Próxima clase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima clase',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(4),
                Text(
                  student.nextClassTime != null
                      ? '${student.nextClassDate} ${student.nextClassTime}'
                      : 'Sin clase programada',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Botón de ver perfil
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // TODO: Navegar al perfil del estudiante
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Ver perfil',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
