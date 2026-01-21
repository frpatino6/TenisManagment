import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/models/tenant_payment_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantPaymentsListScreen extends ConsumerStatefulWidget {
  const TenantPaymentsListScreen({super.key});

  @override
  ConsumerState<TenantPaymentsListScreen> createState() =>
      _TenantPaymentsListScreenState();
}

class _TenantPaymentsListScreenState
    extends ConsumerState<TenantPaymentsListScreen> {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(tenantPaymentsProvider);
    final dateRange = ref.watch(paymentsDateRangeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        actions: [
          IconButton(
            onPressed: () => _pickDateRange(context, dateRange),
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            onPressed: () => ref.refresh(tenantPaymentsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeBanner(context, dateRange),
          Expanded(
            child: paymentsAsync.when(
              data: (data) => _buildPaymentsList(context, data, theme),
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget.fromError(
                error,
                onRetry: () => ref.refresh(tenantPaymentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBanner(BuildContext context, DateTimeRange? range) {
    if (range == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rango: ${_dateFormatter.format(range.start)} - ${_dateFormatter.format(range.end)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(paymentsDateRangeProvider.notifier).setRange(null);
              ref.read(paymentsPageProvider.notifier).setPage(1);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    TenantPaymentsResponse data,
    ThemeData theme,
  ) {
    final payments = data.payments;
    final pagination = data.pagination;

    if (payments.isEmpty) {
      return const Center(
        child: Text('No se encontraron pagos con los filtros aplicados.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Mostrando ${payments.length} de ${pagination.total} pagos',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Página ${pagination.page} / ${pagination.totalPages}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: payments.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildPaymentCard(context, payments[index]);
            },
          ),
        ),
        _buildPaginationControls(context, pagination),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, TenantPaymentModel payment) {
    final status = _statusLabel(payment.status);
    final statusColor = _statusColor(payment.status, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CurrencyUtils.format(payment.amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              _dateFormatter.format(payment.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(4),
            Text(
              'Referencia: ${payment.reference}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(4),
            Text(
              'Gateway: ${payment.gateway}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    PaymentsPagination pagination,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: pagination.hasPreviousPage
                  ? () => ref
                        .read(paymentsPageProvider.notifier)
                        .setPage(pagination.page - 1)
                  : null,
              child: const Text('Anterior'),
            ),
          ),
          const Gap(12),
          Expanded(
            child: OutlinedButton(
              onPressed: pagination.hasNextPage
                  ? () => ref
                        .read(paymentsPageProvider.notifier)
                        .setPage(pagination.page + 1)
                  : null,
              child: const Text('Siguiente'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    DateTimeRange? current,
  ) async {
    final now = DateTime.now();
    final initialRange =
        current ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      ref.read(paymentsDateRangeProvider.notifier).setRange(picked);
      ref.read(paymentsPageProvider.notifier).setPage(1);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Aprobado';
      case 'PENDING':
        return 'Pendiente';
      case 'DECLINED':
        return 'Rechazado';
      case 'VOIDED':
        return 'Anulado';
      case 'ERROR':
        return 'Error';
      default:
        return status;
    }
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'DECLINED':
        return Colors.red;
      case 'VOIDED':
        return Colors.grey;
      case 'ERROR':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
