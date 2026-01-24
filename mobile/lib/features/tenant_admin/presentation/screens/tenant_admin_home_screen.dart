import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_metrics_model.dart';

class TenantAdminHomeScreen extends ConsumerWidget {
  const TenantAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final metricsAsync = ref.watch(tenantMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showProfileMenu(context, ref),
            icon: Icon(
              Icons.account_circle_outlined,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) => _buildDashboard(context, metrics, ref),
        loading: () => const LoadingWidget(message: 'Cargando métricas...'),
        error: (error, stackTrace) {
          // Check if it's an authentication error
          if (error is AuthException) {
            // Redirect to login on auth errors
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/login');
              }
            });
            return const SizedBox.shrink();
          }
          return AppErrorWidget.fromError(
            error,
            onRetry: () => ref.invalidate(tenantMetricsProvider),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    TenantMetricsModel metrics,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tenantMetricsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const Gap(24),
            _buildQuickActionsSection(context),
            const Gap(24),
            _buildTopProfessorsSection(context, metrics),
            const Gap(24),
            _buildMetricsGrid(context, metrics),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: colorScheme.onPrimary,
                size: 32,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'Panel de Administración',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'Gestiona tu centro deportivo',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/tenant-admin-home/config');
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Configurar Centro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onPrimary,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, metrics) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Principales',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              context,
              'Pagos',
              metrics.payments.total.toString(),
              Icons.payment,
              Colors.teal,
              onTap: () => context.push('/tenant-admin-home/payments'),
              hint: 'Ver detalle',
            ),
            _buildMetricCard(
              context,
              'Reservas',
              metrics.bookings.total.toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildMetricCard(
              context,
              'Ingresos',
              CurrencyUtils.format(metrics.payments.revenue.toDouble()),
              Icons.attach_money,
              Colors.green,
            ),
            _buildMetricCard(
              context,
              'Profesores',
              metrics.users.professors.toString(),
              Icons.person,
              Colors.orange,
            ),
            _buildMetricCard(
              context,
              'Estudiantes',
              metrics.users.students.toString(),
              Icons.people,
              Colors.purple,
            ),
            _buildMetricCard(
              context,
              'Canchas',
              metrics.courts.total.toString(),
              Icons.sports_tennis,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    String? hint,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Gap(12),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Gap(4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hint != null) ...[
                const Gap(4),
                Row(
                  children: [
                    Text(
                      hint,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfessorsSection(BuildContext context, metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (metrics.topProfessors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profesores Más Activos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(16),
        ...metrics.topProfessors.map(
          (professor) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professor.professorName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${professor.bookingsCount} reservas',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildQuickActionCard(
              context,
              title: 'Reservas',
              subtitle: 'Ver reservas',
              icon: Icons.calendar_today,
              color: Colors.purple,
              onTap: () => context.push('/tenant-admin-home/bookings'),
            ),
            _buildQuickActionCard(
              context,
              title: 'Profesores',
              subtitle: 'Gestionar profesores',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => context.push('/tenant-admin-home/professors'),
            ),
            _buildQuickActionCard(
              context,
              title: 'Canchas',
              subtitle: 'Gestionar canchas',
              icon: Icons.sports_tennis,
              color: Colors.green,
              onTap: () => context.push('/tenant-admin-home/courts'),
            ),
            _buildQuickActionCard(
              context,
              title: 'Estudiantes',
              subtitle: 'Gestionar estudiantes',
              icon: Icons.people_outline,
              color: Colors.orange,
              onTap: () => context.push('/tenant-admin-home/students'),
            ),
            _buildQuickActionCard(
              context,
              title: 'Facturación',
              subtitle: 'Ver ingresos',
              icon: Icons.bar_chart,
              color: Colors.teal,
              onTap: () => context.push('/tenant-admin-home/bookings/stats'),
            ),
            _buildQuickActionCard(
              context,
              title: 'Deudas',
              subtitle: 'Reporte deudores',
              icon: Icons.money_off_rounded,
              color: Colors.red,
              onTap: () => context.push('/tenant-admin-home/reports/debts'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
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
          padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const Gap(8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
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
              leading: Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Configuración de Tema'),
              onTap: () {
                Navigator.pop(context);
                context.push('/theme-settings');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, ref);
              },
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
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
