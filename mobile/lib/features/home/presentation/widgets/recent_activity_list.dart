import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../student/domain/models/recent_activity_model.dart';

class RecentActivityList extends ConsumerWidget {
  final UserModel user;

  const RecentActivityList({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!user.isProfessor) {
      final activitiesAsync = ref.watch(recentActivitiesProvider);

      return activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildActivitiesList(context, activities);
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(context, error),
      );
    }

    final activities = _getProfessorActivities();
    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildProfessorActivitiesList(context, activities);
  }

  Widget _buildActivitiesList(
    BuildContext context,
    List<RecentActivityModel> activities,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(context, activity, index);
      },
    );
  }

  Widget _buildProfessorActivitiesList(
    BuildContext context,
    List<ActivityItem> activities,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildProfessorActivityItem(context, activity, index);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const Gap(16),
                Text(
                  'No hay actividad reciente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(8),
                Text(
                  user.isProfessor
                      ? 'Tus actividades como profesor aparecerán aquí'
                      : 'Tus reservas y actividades aparecerán aquí',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const Gap(16),
            Text(
              'Error al cargar actividades',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    RecentActivityModel activity,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityColor = _getColorFromString(activity.color);
    final activityIcon = _getIconFromString(activity.icon);

    return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activityIcon, color: activityColor, size: 20),
            ),
            title: Text(
              activity.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(4),
                Text(
                  activity.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(4),
                Text(
                  activity.timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(activity.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusLabel(activity.status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getStatusColor(activity.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              // TODO: Implement activity detail navigation
            },
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildProfessorActivityItem(
    BuildContext context,
    ActivityItem activity,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activity.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activity.icon, color: activity.color, size: 20),
            ),
            title: Text(
              activity.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(4),
                Text(
                  activity.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(4),
                Text(
                  activity.timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            trailing: activity.status != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        activity.status!,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.status!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(activity.status!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : null,
            onTap: activity.onTap,
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, end: 0);
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'calendar_today':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'support_agent':
        return Icons.support_agent;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'book_online':
        return Icons.book_online;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmado';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelado';
      case 'completed':
        return 'Completado';
      case 'requested':
        return 'Solicitado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'completed':
      case 'confirmado':
      case 'confirmed':
        return Colors.green;
      case 'pendiente':
      case 'pending':
      case 'requested':
        return Colors.orange;
      case 'cancelado':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  List<ActivityItem> _getProfessorActivities() {
    // Hardcoded data for professors (for now)
    return [
      ActivityItem(
        title: 'Clase con Juan Pérez',
        description: 'Clase de tenis - Cancha 1',
        timeAgo: 'Hace 2 horas',
        icon: Icons.sports_tennis,
        color: Colors.green,
        status: 'Completado',
        onTap: () {},
      ),
      ActivityItem(
        title: 'Nueva reserva',
        description: 'María García - Mañana 10:00 AM',
        timeAgo: 'Hace 4 horas',
        icon: Icons.book_online,
        color: Colors.blue,
        status: 'Pendiente',
        onTap: () {},
      ),
      ActivityItem(
        title: 'Pago recibido',
        description: 'Carlos López - \$50.000',
        timeAgo: 'Ayer',
        icon: Icons.payment,
        color: Colors.orange,
        status: 'Confirmado',
        onTap: () {},
      ),
    ];
  }
}

class ActivityItem {
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final String? status;
  final VoidCallback onTap;

  ActivityItem({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.color,
    this.status,
    required this.onTap,
  });
}
