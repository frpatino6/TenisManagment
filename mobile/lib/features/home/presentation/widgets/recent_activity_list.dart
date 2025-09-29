import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/domain/models/user_model.dart';

class RecentActivityList extends StatelessWidget {
  final UserModel user;

  const RecentActivityList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final activities = _getRecentActivities();

    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }

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

  Widget _buildActivityItem(
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
                      color: _getStatusColor(activity.status!).withValues(alpha: 0.1),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'confirmado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  List<ActivityItem> _getRecentActivities() {
    // TODO: Implementar lógica real para obtener actividades recientes
    // Por ahora retornamos datos de ejemplo
    if (user.isProfessor) {
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
    } else {
      return [
        ActivityItem(
          title: 'Clase reservada',
          description: 'Prof. Ana Martínez - Cancha 2',
          timeAgo: 'Hace 1 hora',
          icon: Icons.calendar_today,
          color: Colors.blue,
          status: 'Confirmado',
          onTap: () {},
        ),
        ActivityItem(
          title: 'Pago realizado',
          description: 'Clase del 15 de enero - \$50.000',
          timeAgo: 'Hace 3 horas',
          icon: Icons.payment,
          color: Colors.green,
          status: 'Completado',
          onTap: () {},
        ),
        ActivityItem(
          title: 'Solicitud de servicio',
          description: 'Clase privada - Pendiente de aprobación',
          timeAgo: 'Ayer',
          icon: Icons.support_agent,
          color: Colors.orange,
          status: 'Pendiente',
          onTap: () {},
        ),
      ];
    }
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
