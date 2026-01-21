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
          _buildQuickRanges(context, dateRange),
          _buildFiltersRow(context),
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

  Widget _buildQuickRanges(
    BuildContext context,
    DateTimeRange? currentRange,
  ) {
    final now = DateTime.now();
    final ranges = [
      _QuickRange(
        label: '7 días',
        range: DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: now,
        ),
      ),
      _QuickRange(
        label: '30 días',
        range: DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 29),
          end: now,
        ),
      ),
      _QuickRange(
        label: '90 días',
        range: DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 89),
          end: now,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 8,
        children: ranges.map((range) {
          final isSelected = currentRange != null &&
              _isSameDay(currentRange.start, range.range.start) &&
              _isSameDay(currentRange.end, range.range.end);

          return ChoiceChip(
            label: Text(range.label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(paymentsDateRangeProvider.notifier).setRange(range.range);
              ref.read(paymentsPageProvider.notifier).setPage(1);
            },
          );
        }).toList(),
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

  Widget _buildFiltersRow(BuildContext context) {
    final status = ref.watch(paymentStatusFilterProvider);
    final method = ref.watch(paymentMethodFilterProvider);
    final channel = ref.watch(paymentChannelFilterProvider);

    final statusOptions = const <String, String>{
      'APPROVED': 'Aprobado',
      'PENDING': 'Pendiente',
      'DECLINED': 'Rechazado',
      'VOIDED': 'Anulado',
      'ERROR': 'Error',
    };
    final methodOptions = const <String, String>{
      'CARD': 'Tarjeta',
      'PSE': 'PSE',
      'NEQUI': 'Nequi',
      'BANCOLOMBIA_TRANSFER': 'Transferencia',
    };
    final channelOptions = const <String, String>{
      'direct': 'Pago directo',
      'wallet': 'Monedero',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildFilterChip(
            label: 'Estado',
            options: statusOptions,
            value: status,
            onSelected: (value) {
              ref.read(paymentStatusFilterProvider.notifier).setStatus(value);
              ref.read(paymentsPageProvider.notifier).setPage(1);
            },
          ),
          _buildFilterChip(
            label: 'Método',
            options: methodOptions,
            value: method,
            onSelected: (value) {
              ref.read(paymentMethodFilterProvider.notifier).setMethod(value);
              ref.read(paymentsPageProvider.notifier).setPage(1);
            },
          ),
          _buildFilterChip(
            label: 'Canal',
            options: channelOptions,
            value: channel,
            onSelected: (value) {
              ref.read(paymentChannelFilterProvider.notifier).setChannel(value);
              ref.read(paymentsPageProvider.notifier).setPage(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Map<String, String> options,
    required String? value,
    required ValueChanged<String?> onSelected,
  }) {
    return PopupMenuButton<String?>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Todos'),
        ),
        ...options.entries.map(
          (entry) => PopupMenuItem<String?>(
            value: entry.key,
            child: Text(entry.value),
          ),
        ),
      ],
      child: Chip(
        label: Text(
          value == null
              ? label
              : '${label}: ${options[value] ?? value}',
        ),
        deleteIcon: value == null ? null : const Icon(Icons.close, size: 16),
        onDeleted: value == null ? null : () => onSelected(null),
      ),
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
              payment.studentName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Gap(2),
            Text(
              'Referencia: ${payment.reference}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (payment.customerEmail != null &&
                payment.customerEmail!.isNotEmpty) ...[
              const Gap(2),
              Text(
                payment.customerEmail!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (payment.paymentMethodType != null &&
                payment.paymentMethodType!.isNotEmpty) ...[
              const Gap(2),
              Text(
                'Método: ${_formatMethodType(payment.paymentMethodType!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Gap(4),
            Text(
              'Gateway: ${payment.gateway}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (payment.channel != null) ...[
              const Gap(2),
              Text(
                'Canal: ${_formatChannel(payment.channel!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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

  String _formatMethodType(String method) {
    switch (method.toUpperCase()) {
      case 'CARD':
        return 'Tarjeta';
      case 'PSE':
        return 'PSE';
      case 'NEQUI':
        return 'Nequi';
      case 'BANCOLOMBIA_TRANSFER':
        return 'Transferencia';
      default:
        return method;
    }
  }

  String _formatChannel(String channel) {
    switch (channel) {
      case 'direct':
        return 'Pago directo';
      case 'wallet':
        return 'Monedero';
      default:
        return channel;
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _QuickRange {
  final String label;
  final DateTimeRange range;

  _QuickRange({required this.label, required this.range});
}
