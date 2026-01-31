import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/models/tenant_student_model.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantStudentDetailsScreen extends ConsumerStatefulWidget {
  final String studentId;

  const TenantStudentDetailsScreen({super.key, required this.studentId});

  @override
  ConsumerState<TenantStudentDetailsScreen> createState() =>
      _TenantStudentDetailsScreenState();
}

class _TenantStudentDetailsScreenState
    extends ConsumerState<TenantStudentDetailsScreen> {
  bool _isUpdatingBalance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Estudiante')),
      body: FutureBuilder<TenantStudentDetailsModel>(
        future: ref
            .read(tenantAdminServiceProvider)
            .getStudentDetails(widget.studentId),
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
            return const Center(child: Text('Estudiante no encontrado'));
          }

          final student = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, student),
                const Gap(16),
                _buildBalanceCard(context, student),
                const Gap(16),
                _buildRecentBookings(context, student.recentBookings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    TenantStudentDetailsModel student,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: theme.textTheme.titleLarge),
                      Text(
                        student.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      if (student.phone != null)
                        Text(student.phone!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(
                  context,
                  label: 'Membresía',
                  value: student.membershipType.toUpperCase(),
                  color: colorScheme.secondary,
                ),
                _buildInfoBadge(
                  context,
                  label: 'Estado',
                  value: student.isActive ? 'ACTIVO' : 'INACTIVO',
                  color: student.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    TenantStudentDetailsModel student,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance en el Centro',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      CurrencyUtils.format(student.balance),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: student.balance >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                if (!_isUpdatingBalance)
                  ElevatedButton.icon(
                    onPressed: () => _showBalanceDialog(context, student),
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Ajustar'),
                  ),
              ],
            ),
            if (_isUpdatingBalance)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings(
    BuildContext context,
    List<TenantBookingModel> bookings,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('Reservas Recientes', style: theme.textTheme.titleMedium),
        ),
        if (bookings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay reservas recientes')),
            ),
          )
        else
          ...bookings.map((booking) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  _getServiceTypeLabel(booking.serviceType),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  booking.date != null
                      ? dateFormat.format(booking.date!)
                      : 'Fecha no disponible',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(booking.price),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInfoBadge(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
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

  Future<void> _showBalanceDialog(
    BuildContext context,
    TenantStudentDetailsModel student,
  ) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String type = 'add'; // 'add', 'subtract', 'set'

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajustar Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de operación',
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Agregar saldo')),
                  DropdownMenuItem(
                    value: 'subtract',
                    child: Text('Restar saldo'),
                  ),
                  DropdownMenuItem(
                    value: 'set',
                    child: Text('Establecer saldo fijo'),
                  ),
                ],
                onChanged: (val) => setDialogState(() => type = val!),
              ),
              const Gap(12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const Gap(12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final amount = double.tryParse(amountController.text);
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monto inválido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _updateBalance(student.id, amount, type, reasonController.text);
    }
  }

  Future<void> _updateBalance(
    String studentId,
    double amount,
    String type,
    String reason,
  ) async {
    setState(() => _isUpdatingBalance = true);

    try {
      await ref
          .read(tenantAdminServiceProvider)
          .updateStudentBalance(
            studentId,
            amount: amount,
            type: type,
            reason: reason.isEmpty ? null : reason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balance actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh view
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
        setState(() => _isUpdatingBalance = false);
      }
    }
  }
}
