import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/models/recent_activity_model.dart';
import '../providers/student_provider.dart';

class RecentActivityScreen extends ConsumerStatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  ConsumerState<RecentActivityScreen> createState() =>
      _RecentActivityScreenState();
}

class _RecentActivityScreenState
    extends ConsumerState<RecentActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _typeFilter;
  String? _lastRouteName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final currentRouteName = route?.settings.name;

    if (route != null &&
        route.isCurrent &&
        currentRouteName != null &&
        currentRouteName != _lastRouteName) {
      _lastRouteName = currentRouteName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(recentActivitiesTabProvider(_typeFilter));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.recentActivity,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(recentActivitiesTabProvider(_typeFilter));
              if (_tabController.index == 1) {
                ref.invalidate(activityHistoryProvider(_typeFilter));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          onTap: (index) {
            if (index == 1 && _tabController.previousIndex == 0) {
              ref.read(activityHistoryProvider(_typeFilter));
            }
          },
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time, size: 20),
              text: 'Recientes',
            ),
            Tab(
              icon: Icon(Icons.history, size: 20),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ref
              .watch(recentActivitiesTabProvider(_typeFilter))
              .when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return _buildEmptyState(context, 'No hay actividades recientes');
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(recentActivitiesTabProvider(_typeFilter));
                    },
                    child: _buildRecentList(activities),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, stack) => AppErrorWidget.fromError(
                  error,
                  onRetry: () =>
                      ref.invalidate(recentActivitiesTabProvider(_typeFilter)),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ref
              .watch(activityHistoryProvider(_typeFilter))
              .when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return _buildEmptyState(
                      context,
                      'No hay actividades en el historial',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(activityHistoryProvider(_typeFilter));
                    },
                    child: _buildHistoryList(activities),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, stack) => AppErrorWidget.fromError(
                  error,
                  onRetry: () =>
                      ref.invalidate(activityHistoryProvider(_typeFilter)),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', null),
            const Gap(8),
            _buildFilterChip('Reservas', 'booking'),
            const Gap(8),
            _buildFilterChip('Pagos', 'payment'),
            const Gap(8),
            _buildFilterChip('Solicitudes', 'service_request'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _typeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _typeFilter = selected ? value : null;
        });
        ref.invalidate(recentActivitiesTabProvider(_typeFilter));
        if (_tabController.index == 1) {
          ref.invalidate(activityHistoryProvider(_typeFilter));
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildRecentList(List<RecentActivityModel> activities) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final todayActivities = <RecentActivityModel>[];
    final thisWeekActivities = <RecentActivityModel>[];
    final olderActivities = <RecentActivityModel>[];

    for (final activity in activities) {
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );

      if (activityDate.isAtSameMomentAs(startOfToday) ||
          (activityDate.isAfter(startOfToday) &&
              activityDate.isBefore(endOfToday))) {
        todayActivities.add(activity);
      } else if (activityDate.compareTo(startOfWeek) >= 0 &&
          activityDate.compareTo(endOfWeek) < 0) {
        thisWeekActivities.add(activity);
      } else {
        olderActivities.add(activity);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todayActivities.isNotEmpty) ...[
            _buildSectionHeader(context, 'Hoy', todayActivities.length),
            const Gap(12),
            ...todayActivities.map((activity) => _buildActivityCard(context, activity)),
            const Gap(24),
          ],
          if (thisWeekActivities.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Esta Semana',
              thisWeekActivities.length,
            ),
            const Gap(12),
            ...thisWeekActivities.map(
              (activity) => _buildActivityCard(context, activity),
            ),
            const Gap(24),
          ],
          if (olderActivities.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Más antiguas',
              olderActivities.length,
            ),
            const Gap(12),
            ...olderActivities.map(
              (activity) => _buildActivityCard(context, activity),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<RecentActivityModel> activities) {
    final sortedActivities = List<RecentActivityModel>.from(activities)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedActivities.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(context, sortedActivities[index]);
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    RecentActivityModel activity,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityColor = _getColorFromString(activity.color);
    final activityIcon = _getIconFromString(activity.icon);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: TEN-114 - Implement activity detail navigation
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(activityIcon, color: activityColor, size: 24),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      activity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              ),
              Container(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    RecentActivityModel activity,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityColor = _getColorFromString(activity.color);
    final activityIcon = _getIconFromString(activity.icon);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // TODO: TEN-114 - Implement activity detail navigation
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(activityIcon, color: activityColor, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      activity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const Gap(4),
                        Text(
                          activity.timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(activity.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusLabel(activity.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(activity.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(8),
            Text(
              'Tus actividades aparecerán aquí',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
