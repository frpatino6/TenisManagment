import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/tenant_admin_provider.dart';

class TenantBookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TenantBookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TenantBookingDetailsScreen> createState() =>
      _TenantBookingDetailsScreenState();
}

class _TenantBookingDetailsScreenState
    extends ConsumerState<TenantBookingDetailsScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Reserva')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref
            .read(tenantAdminServiceProvider)
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
          final status = booking['status'] as String;
          final canCancel = status == 'pending' || status == 'confirmed';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context, booking),
                const Gap(16),
                _buildStudentInfo(context, booking),
                const Gap(16),
                _buildBookingInfo(context, booking),
                const Gap(16),
                if (booking['court'] != null) ...[
                  _buildCourtInfo(context, booking),
                  const Gap(16),
                ],
                if (booking['professor'] != null) ...[
                  _buildProfessorInfo(context, booking),
                  const Gap(16),
                ],
                _buildPriceInfo(context, booking),
                const Gap(24),
                if (canCancel && !_isCancelling)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar Reserva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                if (_isCancelling) const LoadingWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
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
        statusText = status;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
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

  Widget _buildStudentInfo(BuildContext context, Map<String, dynamic> booking) {
    final student = booking['student'] as Map<String, dynamic>;
    return _buildInfoCard(
      context,
      title: 'Estudiante',
      icon: Icons.person,
      children: [
        _buildInfoRow('Nombre', student['name'] as String),
        _buildInfoRow('Email', student['email'] as String),
        if (student['phone'] != null)
          _buildInfoRow('Teléfono', student['phone'] as String),
      ],
    );
  }

  Widget _buildBookingInfo(BuildContext context, Map<String, dynamic> booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return _buildInfoCard(
      context,
      title: 'Información de Reserva',
      icon: Icons.event,
      children: [
        if (booking['date'] != null)
          _buildInfoRow(
            'Fecha',
            dateFormat.format(DateTime.parse(booking['date'] as String)),
          ),
        if (booking['startTime'] != null && booking['endTime'] != null)
          _buildInfoRow(
            'Horario',
            '${timeFormat.format(DateTime.parse(booking['startTime'] as String))} - ${timeFormat.format(DateTime.parse(booking['endTime'] as String))}',
          ),
        _buildInfoRow(
          'Tipo',
          _getServiceTypeLabel(booking['serviceType'] as String),
        ),
        if (booking['notes'] != null)
          _buildInfoRow('Notas', booking['notes'] as String),
      ],
    );
  }

  Widget _buildCourtInfo(BuildContext context, Map<String, dynamic> booking) {
    final court = booking['court'] as Map<String, dynamic>;
    return _buildInfoCard(
      context,
      title: 'Cancha',
      icon: Icons.sports_tennis,
      children: [
        _buildInfoRow('Nombre', court['name'] as String),
        _buildInfoRow('Tipo', court['type'] as String),
      ],
    );
  }

  Widget _buildProfessorInfo(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final professor = booking['professor'] as Map<String, dynamic>;
    return _buildInfoCard(
      context,
      title: 'Profesor',
      icon: Icons.school,
      children: [
        _buildInfoRow('Nombre', professor['name'] as String),
        _buildInfoRow('Email', professor['email'] as String),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context, Map<String, dynamic> booking) {
    final theme = Theme.of(context);
    final price = booking['price'] as num;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Precio Total', style: theme.textTheme.titleMedium),
            Text(
              '\$${price.toStringAsFixed(0)}',
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

  Future<void> _showCancelDialog(BuildContext context) async {
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
      await _cancelBooking(reasonController.text.trim());
    }
  }

  Future<void> _cancelBooking(String reason) async {
    setState(() => _isCancelling = true);

    try {
      await ref
          .read(tenantAdminServiceProvider)
          .cancelBooking(
            widget.bookingId,
            reason: reason.isEmpty ? null : reason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate refresh needed
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
