import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/services/schedule_service.dart';
import '../../domain/models/schedule_model.dart';

/// Screen to display professor schedules grouped by tenant (center)
///
/// Shows available schedules for a professor, grouped by the center where they work.
/// Allows students to select a schedule and book a lesson.
class ProfessorSchedulesScreen extends ConsumerStatefulWidget {
  final String professorId;
  final String professorName;

  const ProfessorSchedulesScreen({
    super.key,
    required this.professorId,
    required this.professorName,
  });

  @override
  ConsumerState<ProfessorSchedulesScreen> createState() =>
      _ProfessorSchedulesScreenState();
}

class _ProfessorSchedulesScreenState
    extends ConsumerState<ProfessorSchedulesScreen> {
  ProfessorSchedulesResponse? _schedulesData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(scheduleServiceProvider);
      final data = await service.getProfessorSchedules(widget.professorId);
      
      setState(() {
        _schedulesData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar horarios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectSchedule(ScheduleModel schedule, TenantSchedulesGroup tenantGroup) {
    // Navigate to confirmation screen
    context.push(
      '/confirm-booking',
      extra: {
        'schedule': schedule,
        'professorId': widget.professorId,
        'professorName': widget.professorName,
        'tenantId': tenantGroup.tenantId,
        'tenantName': tenantGroup.tenantName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horarios de ${widget.professorName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSchedules,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _schedulesData == null ||
                      _schedulesData!.schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No hay horarios disponibles',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este profesor no tiene horarios disponibles en este momento',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSchedules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _schedulesData!.schedules.length,
                        itemBuilder: (context, index) {
                          final tenantGroup = _schedulesData!.schedules[index];
                          final isSingleCenter = _schedulesData!.schedules.length == 1;

                          return _buildTenantGroup(tenantGroup, isSingleCenter);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTenantGroup(
      TenantSchedulesGroup tenantGroup, bool isSingleCenter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (tenantGroup.tenantLogo != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(tenantGroup.tenantLogo!),
                    radius: 20,
                  )
                else
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 20,
                    child: const Icon(Icons.business, color: Colors.white),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantGroup.tenantName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${tenantGroup.schedules.length} horario${tenantGroup.schedules.length != 1 ? 's' : ''} disponible${tenantGroup.schedules.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Schedules list
          if (tenantGroup.schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay horarios disponibles en este centro'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tenantGroup.schedules.length,
              itemBuilder: (context, scheduleIndex) {
                final schedule = tenantGroup.schedules[scheduleIndex];
                final isLast = scheduleIndex == tenantGroup.schedules.length - 1;

                return InkWell(
                  onTap: () => _selectSchedule(schedule, tenantGroup),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Day and date
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Text(
                                schedule.dayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                              Text(
                                schedule.startTime.day.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Time and details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule.timeRange,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              if (schedule.notes != null &&
                                  schedule.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    schedule.notes!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Arrow icon
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

