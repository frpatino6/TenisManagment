import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/events/data_change_event.dart';
import '../../../../core/observers/data_change_observer.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../../domain/models/tenant_config_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantBookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final DateTime? gridDate;

  const TenantBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.gridDate,
  });

  @override
  ConsumerState<TenantBookingDetailsScreen> createState() =>
      _TenantBookingDetailsScreenState();
}

class _TenantBookingDetailsScreenState
    extends ConsumerState<TenantBookingDetailsScreen> {
  bool _isCancelling = false;
  bool _isConfirming = false;
  bool _isRescheduling = false;

  (List<(int, int)>, int) _slotsAndLastHourForDate(
    DateTime date,
    TenantConfigModel? tenant,
  ) {
    const defaultFirst = 6;
    const defaultLast = 24;
    int openH = defaultFirst, openM = 0, closeH = defaultLast, closeM = 0;

    final oh = tenant?.config?.operatingHours;
    if (oh != null) {
      if (oh.schedule != null && oh.schedule!.isNotEmpty) {
        final dartWeekday = date.weekday;
        final modelDay = dartWeekday == 7 ? 0 : dartWeekday;
        final daySchedule = oh.schedule!
            .where((s) => s.dayOfWeek == modelDay)
            .toList();
        if (daySchedule.isNotEmpty) {
          final ds = daySchedule.first;
          final o = _parseHHmm(ds.open);
          final c = _parseHHmm(ds.close);
          openH = o.$1;
          openM = o.$2;
          closeH = c.$1;
          closeM = c.$2;
        }
      } else if (oh.open != null && oh.close != null) {
        final o = _parseHHmm(oh.open!);
        final c = _parseHHmm(oh.close!);
        openH = o.$1;
        openM = o.$2;
        closeH = c.$1;
        closeM = c.$2;
      }
    }

    final openMin = openH * 60 + openM;
    final closeMin = closeH * 60 + closeM;
    final slots = <(int, int)>[];
    for (var t = openMin; t <= closeMin - 30; t += 30) {
      slots.add((t ~/ 60, t % 60));
    }
    return (slots, closeH);
  }

  (int, int) _parseHHmm(String s) {
    final parts = s.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (h, m);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Reserva')),
      body: Stack(
        children: [
          FutureBuilder<TenantBookingModel>(
            future: ref
                .read(tenantAdminRepositoryProvider)
                .getBookingDetails(widget.bookingId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (snapshot.hasError) {
                return AppErrorWidget.fromError(
                  snapshot.error!,
                  onRetry: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No se encontró la reserva'));
              }

              final booking = snapshot.data!;
              final canCancel =
                  booking.status == 'pending' || booking.status == 'confirmed';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(context, booking),
                    const Gap(16),
                    _buildStudentInfo(context, booking.student),
                    const Gap(16),
                    _buildBookingInfo(context, booking),
                    const Gap(16),
                    if (booking.court != null) ...[
                      _buildCourtInfo(context, booking.court!),
                      const Gap(16),
                    ],
                    if (booking.professor != null) ...[
                      _buildProfessorInfo(context, booking.professor!),
                      const Gap(16),
                    ],
                    _buildPriceInfo(context, booking.price),
                    const Gap(24),
                    if (booking.serviceType == 'court_rental' &&
                        booking.court != null &&
                        (booking.status == 'pending' ||
                            booking.status == 'confirmed') &&
                        !_isRescheduling &&
                        !_isCancelling &&
                        !_isConfirming)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showRescheduleSheet(context, booking),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Editar horario'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    const Gap(12),
                    if (booking.status == 'pending' &&
                        !_isConfirming &&
                        !_isCancelling) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmDialog(context, booking),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirmar Pago y Reserva'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const Gap(12),
                    ],
                    if (canCancel && !_isCancelling && !_isConfirming)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCancelDialog(context, booking),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar Reserva'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (_isConfirming)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Confirmando reserva...',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Procesando pago y actualizando estado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isRescheduling)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Actualizando horario...',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isCancelling)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cancelando reserva...',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Procesando cancelación',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, TenantBookingModel booking) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Confirmada';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendiente';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelada';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completada';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = booking.status;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado', style: theme.textTheme.bodySmall),
                  Text(
                    statusText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(BuildContext context, StudentInfo student) {
    return _buildInfoCard(
      context,
      title: 'Estudiante',
      icon: Icons.person,
      children: [
        _buildInfoRow('Nombre', student.name),
        _buildInfoRow('Email', student.email),
        if (student.phone != null) _buildInfoRow('Teléfono', student.phone!),
      ],
    );
  }

  Widget _buildBookingInfo(BuildContext context, TenantBookingModel booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return _buildInfoCard(
      context,
      title: 'Información de Reserva',
      icon: Icons.event,
      children: [
        if (booking.date != null)
          _buildInfoRow('Fecha', dateFormat.format(booking.date!)),
        if (booking.startTime != null && booking.endTime != null)
          _buildInfoRow(
            'Horario',
            '${timeFormat.format(booking.startTime!)} - ${timeFormat.format(booking.endTime!)}',
          ),
        _buildInfoRow('Tipo', _getServiceTypeLabel(booking.serviceType)),
        if (booking.notes != null) _buildInfoRow('Notas', booking.notes!),
      ],
    );
  }

  Widget _buildCourtInfo(BuildContext context, CourtInfo court) {
    return _buildInfoCard(
      context,
      title: 'Cancha',
      icon: Icons.sports_tennis,
      children: [
        _buildInfoRow('Nombre', court.name),
        _buildInfoRow('Tipo', court.type),
      ],
    );
  }

  Widget _buildProfessorInfo(BuildContext context, ProfessorInfo professor) {
    return _buildInfoCard(
      context,
      title: 'Profesor',
      icon: Icons.school,
      children: [
        _buildInfoRow('Nombre', professor.name),
        _buildInfoRow('Email', professor.email),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context, double price) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Precio Total', style: theme.textTheme.titleMedium),
            Text(
              CurrencyUtils.format(price),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const Gap(8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getServiceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'individual_class':
        return 'Clase Individual';
      case 'group_class':
        return 'Clase Grupal';
      case 'court_rental':
        return 'Alquiler de Cancha';
      default:
        return serviceType;
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    TenantBookingModel booking,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de que quieres cancelar esta reserva?'),
            const Gap(16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cancelBooking(reasonController.text.trim(), booking);
    }
  }

  Future<void> _showRescheduleSheet(
    BuildContext context,
    TenantBookingModel booking,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseDate = booking.date ?? booking.startTime ?? DateTime.now();
    final start = booking.startTime ?? baseDate;
    final end = booking.endTime ?? start.add(const Duration(minutes: 60));
    final initialDuration = end.difference(start).inMinutes.clamp(60, 120);
    int selectedHour = start.hour;
    int selectedMinute = start.minute;
    int durationMinutes = initialDuration == 90
        ? 90
        : (initialDuration >= 120 ? 120 : 60);

    TenantConfigModel? tenant;
    try {
      tenant = await ref.read(tenantInfoProvider.future);
    } catch (_) {}
    if (!context.mounted) return;
    final (slots, lastHour) = _slotsAndLastHourForDate(baseDate, tenant);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final newStart = DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
              selectedHour,
              selectedMinute,
            );
            final newEnd = newStart.add(Duration(minutes: durationMinutes));
            final endValid =
                newEnd.hour < lastHour ||
                (newEnd.hour == lastHour && newEnd.minute == 0);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Modificar horario',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Gap(16),
                      Text(
                        DateFormat('EEEE d MMM yyyy', 'es').format(baseDate),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(16),
                      Text('Hora de inicio', style: theme.textTheme.titleSmall),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slots.map((s) {
                          final selected =
                              selectedHour == s.$1 && selectedMinute == s.$2;
                          final label =
                              '${s.$1.toString().padLeft(2, '0')}:${s.$2.toString().padLeft(2, '0')}';
                          return FilterChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) {
                              setModalState(() {
                                selectedHour = s.$1;
                                selectedMinute = s.$2;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(16),
                      Text('Duración', style: theme.textTheme.titleSmall),
                      const Gap(8),
                      Row(
                        children: [
                          _rescheduleDurationChip(
                            theme,
                            setModalState,
                            60,
                            '60 min',
                            durationMinutes,
                            (v) => durationMinutes = v,
                          ),
                          const Gap(8),
                          _rescheduleDurationChip(
                            theme,
                            setModalState,
                            90,
                            '90 min',
                            durationMinutes,
                            (v) => durationMinutes = v,
                          ),
                          const Gap(8),
                          _rescheduleDurationChip(
                            theme,
                            setModalState,
                            120,
                            '120 min',
                            durationMinutes,
                            (v) => durationMinutes = v,
                          ),
                        ],
                      ),
                      if (!endValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'El horario debe terminar antes de $lastHour:00',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: endValid
                                  ? () async {
                                      Navigator.of(ctx).pop();
                                      await _executeReschedule(
                                        newStart,
                                        newEnd,
                                        baseDate,
                                      );
                                    }
                                  : null,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _rescheduleDurationChip(
    ThemeData theme,
    void Function(void Function()) setModalState,
    int minutes,
    String label,
    int current,
    void Function(int) onSelect,
  ) {
    final colorScheme = theme.colorScheme;
    final isSelected = current == minutes;
    return Expanded(
      child: InkWell(
        onTap: () => setModalState(() => onSelect(minutes)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeReschedule(
    DateTime newStart,
    DateTime newEnd,
    DateTime baseDate,
  ) async {
    setState(() => _isRescheduling = true);
    try {
      await ref
          .read(tenantAdminRepositoryProvider)
          .rescheduleBooking(
            widget.bookingId,
            startTime: newStart,
            endTime: newEnd,
          );
      ref.invalidate(tenantBookingsProvider);
      final observer = ref.read(dataChangeObserverProvider);
      observer.notifyChange(
        DataChangeEvent(
          changeType: DataChangeType.updated,
          entityType: 'booking',
          entityId: widget.bookingId,
        ),
      );
      final dateToRefresh =
          widget.gridDate ??
          DateTime(baseDate.year, baseDate.month, baseDate.day);
      ref.invalidate(adminCourtGridDataProvider(dateToRefresh));
      await ref.read(adminCourtGridDataProvider(dateToRefresh).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRescheduling = false);
      }
    }
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    TenantBookingModel booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Desea confirmar esta reserva y registrar el pago manual?',
            ),
            const Gap(16),
            Text(
              'Monto: ${CurrencyUtils.format(booking.price)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'El saldo del estudiante se actualizará automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isConfirming = true);

    try {
      await ref
          .read(tenantAdminRepositoryProvider)
          .confirmBooking(widget.bookingId, paymentStatus: 'paid');

      final observer = ref.read(dataChangeObserverProvider);
      observer.notifyChange(
        DataChangeEvent(
          changeType: DataChangeType.updated,
          entityType: 'booking',
          entityId: widget.bookingId,
        ),
      );
      observer.notifyChange(
        DataChangeEvent(
          changeType: DataChangeType.updated,
          entityType: 'payment',
          entityId: widget.bookingId,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva y pago confirmados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _cancelBooking(String reason, TenantBookingModel booking) async {
    setState(() => _isCancelling = true);

    try {
      await ref
          .read(tenantAdminRepositoryProvider)
          .cancelBooking(
            widget.bookingId,
            reason: reason.isEmpty ? null : reason,
          );

      ref.invalidate(tenantBookingsProvider);
      final dateToRefresh =
          widget.gridDate ??
          (booking.date != null
              ? DateTime(
                  booking.date!.year,
                  booking.date!.month,
                  booking.date!.day,
                )
              : (booking.startTime != null
                    ? DateTime(
                        booking.startTime!.year,
                        booking.startTime!.month,
                        booking.startTime!.day,
                      )
                    : null));
      if (dateToRefresh != null) {
        ref.invalidate(adminCourtGridDataProvider(dateToRefresh));
      }
      final observer = ref.read(dataChangeObserverProvider);
      observer.notifyChange(
        DataChangeEvent(
          changeType: DataChangeType.updated,
          entityType: 'booking',
          entityId: widget.bookingId,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}
