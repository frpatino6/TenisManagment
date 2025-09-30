import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/models/user_model.dart';

class QuickActionsGrid extends StatelessWidget {
  final UserModel user;

  const QuickActionsGrid({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final actions = user.isProfessor
        ? _getProfessorActions()
        : _getStudentActions(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(context, action, index);
      },
    );
  }

  Widget _buildActionCard(BuildContext context, QuickAction action, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withValues(alpha: 0.1),
                action.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono
              Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: action.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, size: 18, color: Colors.white),
                  )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    delay: (index * 100).ms,
                  )
                  .fadeIn(duration: 400.ms, delay: (index * 100).ms),

              const Gap(6),

              // Título
              Flexible(
                child:
                    Text(
                          action.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: (index * 100 + 200).ms)
                        .slideY(begin: 0.2, end: 0),
              ),

              const Gap(4),

              // Subtítulo
              Text(
                    action.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (index * 100 + 400).ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  List<QuickAction> _getProfessorActions() {
    return [
      QuickAction(
        title: 'Publicar Horario',
        subtitle: 'Gestiona tu disponibilidad',
        icon: Icons.schedule,
        color: Colors.blue,
        onTap: () {
          // TODO: Implementar publicación de horario
        },
      ),
      QuickAction(
        title: 'Mis Estudiantes',
        subtitle: 'Ve tus estudiantes',
        icon: Icons.people,
        color: Colors.green,
        onTap: () {
          // TODO: Implementar lista de estudiantes
        },
      ),
      QuickAction(
        title: 'Ingresos',
        subtitle: 'Revisa tus ganancias',
        icon: Icons.attach_money,
        color: Colors.orange,
        onTap: () {
          // TODO: Implementar seguimiento de ingresos
        },
      ),
      QuickAction(
        title: 'Servicios',
        subtitle: 'Gestiona servicios',
        icon: Icons.sports_tennis,
        color: Colors.purple,
        onTap: () {
          // TODO: Implementar gestión de servicios
        },
      ),
    ];
  }

  List<QuickAction> _getStudentActions(BuildContext context) {
    return [
      QuickAction(
        title: 'Reservar Clase',
        subtitle: 'Encuentra horarios disponibles',
        icon: Icons.book_online,
        color: Colors.blue,
        onTap: () {
          context.push('/book-class');
        },
      ),
      QuickAction(
        title: 'Mis Reservas',
        subtitle: 'Ve tus clases reservadas',
        icon: Icons.calendar_today,
        color: Colors.green,
        onTap: () {
          // TODO: Implementar lista de reservas
        },
      ),
      QuickAction(
        title: 'Mi Balance',
        subtitle: 'Revisa tu saldo',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        onTap: () {
          // TODO: Implementar consulta de balance
        },
      ),
      QuickAction(
        title: 'Solicitar Servicio',
        subtitle: 'Pide servicios especiales',
        icon: Icons.support_agent,
        color: Colors.purple,
        onTap: () {
          // TODO: Implementar solicitud de servicios
        },
      ),
    ];
  }
}

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
