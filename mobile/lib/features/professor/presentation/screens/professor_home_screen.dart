import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/version_widget.dart';
import '../../../../core/widgets/update_check_wrapper.dart';
import '../widgets/professor_profile_card.dart';
import '../widgets/schedule_widget.dart';
import '../widgets/earnings_widget.dart';
import '../widgets/tenant_selector_widget.dart';
import '../providers/professor_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfessorHomeScreen extends ConsumerStatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  ConsumerState<ProfessorHomeScreen> createState() =>
      _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends ConsumerState<ProfessorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final professorInfo = ref.watch(professorInfoProvider);

    return UpdateCheckWrapper(
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Panel del Profesor',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/manage-schedules'),
            icon: Icon(Icons.calendar_month, color: colorScheme.onSurface),
            tooltip: 'Ver mis horarios',
          ),
          IconButton(
            onPressed: () => _showProfileMenu(context),
            icon: Icon(
              Icons.account_circle_outlined,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: professorInfo.when(
        data: (professor) {
          return _buildProfessorContent(context, professor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      ),
    );
  }

  Widget _buildProfessorContent(BuildContext context, professor) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(professorNotifierProvider.notifier).refreshAll();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, professor),
            const Gap(24),

            // Tenant selector for professors with multiple centers
            const TenantSelectorWidget(),
            const Gap(24),

            const ProfessorProfileCard(),
            const Gap(24),

            _buildTodaySchedule(context),
            const Gap(24),

            _buildQuickActionsGrid(context),
            const Gap(24),

            _buildQuickStats(context),
            const Gap(24),

            _buildEarningsSection(context),
            const Gap(24),
            Center(
              child:
                  VersionBadge(
                        showBuildNumber: true,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 1200.ms)
                      .slideY(begin: 0.2, end: 0),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, professor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido, ${professor.name}!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
          const Gap(8),
          Text(
                'Gestiona tus clases y estudiantes de manera eficiente',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideX(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final professorInfo = ref.watch(professorInfoProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);
    final earningsStats = ref.watch(earningsStatsProvider);

    return professorInfo.when(
      data: (professor) {
        return todaySchedule.when(
          data: (classes) {
            return earningsStats.when(
              data: (earnings) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estadísticas Rápidas',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Estudiantes',
                            professor.totalStudents.toString(),
                            Icons.people_outline,
                            colorScheme.primary,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Clases Hoy',
                            classes.length.toString(),
                            Icons.schedule_outlined,
                            colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Ganancias',
                            '\$${(earnings['weeklyEarnings'] ?? 0).toStringAsFixed(0)}',
                            Icons.attach_money_outlined,
                            Colors.green,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Rating',
                            professor.rating.toStringAsFixed(1),
                            Icons.star_outline,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => _buildLoadingStats(context),
              error: (error, stackTrace) => _buildErrorStats(context, error),
            );
          },
          loading: () => _buildLoadingStats(context),
          error: (error, stackTrace) => _buildErrorStats(context, error),
        );
      },
      loading: () => _buildLoadingStats(context),
      error: (error, stackTrace) => _buildErrorStats(context, error),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
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
              Icon(icon, color: color, size: 24),
              const Gap(8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
        .animate()
        .scale(duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildQuickActionCard(
          context: context,
          icon: Icons.people,
          title: 'Mis Estudiantes',
          subtitle: 'Ver lista completa',
          color: Colors.blue,
          onTap: () {
            context.push('/students-list');
          },
        ),
        _buildQuickActionCard(
          context: context,
          icon: Icons.calendar_today,
          title: 'Mis Horarios',
          subtitle: 'Gestionar disponibilidad',
          color: Colors.green,
          onTap: () {
            context.push('/manage-schedules');
          },
        ),
        _buildQuickActionCard(
          context: context,
          icon: Icons.add_circle,
          title: 'Crear Horario',
          subtitle: 'Agregar disponibilidad',
          color: Colors.orange,
          onTap: () {
            context.push('/create-schedule');
          },
        ),
        _buildQuickActionCard(
          context: context,
          icon: Icons.analytics,
          title: 'Analytics',
          subtitle: 'Dashboard de métricas',
          color: Colors.teal,
          onTap: () {
            context.push('/analytics-dashboard');
          },
        ),
        _buildQuickActionCard(
          context: context,
          icon: Icons.price_change,
          title: 'Precios',
          subtitle: 'Configurar tarifas',
          color: Colors.purple,
          onTap: () {
            context.push('/pricing-config');
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Gap(8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horarios de Hoy',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
        const Gap(16),
        const ScheduleWidget(),
      ],
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ganancias del Mes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
        const Gap(16),
        const EarningsWidget(),
      ],
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Rápidas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(16),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorStats(BuildContext context, error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Rápidas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(16),
        Center(
          child: Text(
            'Error al cargar estadísticas: $error',
            style: GoogleFonts.inter(color: colorScheme.error),
          ),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              onTap: () {
                Navigator.pop(context);
                context.push('/theme-settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
        }
      }
    }
  }
}
