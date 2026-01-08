import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/tenant_admin_provider.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';

class TenantBookingCalendarScreen extends ConsumerStatefulWidget {
  const TenantBookingCalendarScreen({super.key});

  @override
  ConsumerState<TenantBookingCalendarScreen> createState() =>
      _TenantBookingCalendarScreenState();
}

class _TenantBookingCalendarScreenState
    extends ConsumerState<TenantBookingCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Cache for calendar events
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Normalize date to remove time for lookup
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We fetch a wide range to cover the month view
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

    final calendarAsync = ref.watch(
      bookingCalendarProvider((from: firstDay, to: lastDay)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Reservas')),
      body: calendarAsync.when(
        data: (data) {
          // Update events cache
          _events = {};
          data.forEach((dateStr, bookings) {
            final date = DateTime.parse(dateStr);
            final normalizedDate = DateTime(date.year, date.month, date.day);
            _events[normalizedDate] = bookings;
          });

          final selectedEvents = _getEventsForDay(_selectedDay!);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
              ),
              const Divider(),
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const Gap(16),
                            Text(
                              'No hay reservas para este día',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final bookingRaw =
                              selectedEvents[index] as Map<String, dynamic>;
                          // We can convert to TenantBookingModel if needed or use raw map
                          // For simplicity in calendar view, we use the raw data or a mini model
                          final timeStr = bookingRaw['startTime'] != null
                              ? DateFormat('HH:mm').format(
                                  DateTime.parse(bookingRaw['startTime']),
                                )
                              : '--:--';
                          final studentName =
                              bookingRaw['studentName'] ?? 'Estudiante';
                          final status = bookingRaw['status'] ?? 'pending';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Text(
                                timeStr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              title: Text(studentName),
                              subtitle: Text(_getStatusLabel(status)),
                              trailing: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                              onTap: () {
                                final id = bookingRaw['id'];
                                if (id != null) {
                                  context.push(
                                    '/tenant-admin-home/bookings/$id',
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Cargando calendario...'),
        error: (error, stack) => AppErrorWidget.fromError(
          error,
          onRetry: () => ref.refresh(
            bookingCalendarProvider((from: firstDay, to: lastDay)),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
