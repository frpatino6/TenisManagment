import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/tenant_professor_model.dart';

class ProfessorScheduleTab extends ConsumerWidget {
  final TenantProfessorModel professor;

  const ProfessorScheduleTab({super.key, required this.professor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        'Próximamente: Agenda de ${professor.name}',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
