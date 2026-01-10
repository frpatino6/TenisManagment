import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/tenant_admin_provider.dart';
import '../widgets/professor_profile_tab.dart';
import '../widgets/professor_schedule_tab.dart';
import '../widgets/professor_stats_tab.dart';

class TenantProfessorDetailsScreen extends ConsumerStatefulWidget {
  final String professorId;

  const TenantProfessorDetailsScreen({super.key, required this.professorId});

  @override
  ConsumerState<TenantProfessorDetailsScreen> createState() =>
      _TenantProfessorDetailsScreenState();
}

class _TenantProfessorDetailsScreenState
    extends ConsumerState<TenantProfessorDetailsScreen>
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
    // final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;
    final professorsAsync = ref.watch(tenantProfessorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalle del Profesor',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          tabs: const [
            Tab(text: 'Perfil'),
            Tab(text: 'Agenda'),
            Tab(text: 'Estadísticas'),
          ],
        ),
      ),
      body: professorsAsync.when(
        data: (professors) {
          try {
            final professor = professors.firstWhere(
              (p) => p.id == widget.professorId,
            );

            return TabBarView(
              controller: _tabController,
              children: [
                ProfessorProfileTab(professor: professor),
                ProfessorScheduleTab(professor: professor),
                ProfessorStatsTab(professor: professor),
              ],
            );
          } catch (e) {
            return Center(
              child: Text(
                'Profesor no encontrado',
                style: GoogleFonts.inter(fontSize: 16),
              ),
            );
          }
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget.fromError(
          error,
          onRetry: () => ref.refresh(tenantProfessorsProvider),
        ),
      ),
    );
  }
}
