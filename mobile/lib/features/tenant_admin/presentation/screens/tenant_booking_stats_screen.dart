import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/tenant_admin_provider.dart';
import '../widgets/executive_billing_summary.dart';

class TenantBookingStatsScreen extends ConsumerWidget {
  const TenantBookingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bookingStatsProvider);
    final dateRange = ref.watch(bookingStatsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación'),
        actions: [
          IconButton(
            onPressed: () => _pickDateRange(context, ref, dateRange),
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            onPressed: () => ref.refresh(bookingStatsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (bookingStats) => Column(
          children: [
            _buildDateRangeBanner(context, ref, dateRange),
            _buildQuickRanges(context, ref, dateRange),
            Expanded(
              child: ExecutiveBillingSummary(
                stats: bookingStats,
                onViewDetails: () =>
                    context.push('/tenant-admin-home/payments'),
              ),
            ),
          ],
        ),
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget.fromError(
          error,
          onRetry: () => ref.refresh(bookingStatsProvider),
        ),
      ),
    );
  }

  Widget _buildDateRangeBanner(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? range,
  ) {
    if (range == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rango: ${_formatDate(range.start)} - ${_formatDate(range.end)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookingStatsDateRangeProvider.notifier).setRange(null);
              ref.invalidate(bookingStatsProvider);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRanges(
    BuildContext context,
    WidgetRef ref,
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
          final isSelected =
              currentRange != null &&
              _isSameDay(currentRange.start, range.range.start) &&
              _isSameDay(currentRange.end, range.range.end);

          return ChoiceChip(
            label: Text(range.label),
            selected: isSelected,
            onSelected: (_) {
              ref
                  .read(bookingStatsDateRangeProvider.notifier)
                  .setRange(range.range);
              ref.invalidate(bookingStatsProvider);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    WidgetRef ref,
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
      ref.read(bookingStatsDateRangeProvider.notifier).setRange(picked);
      ref.invalidate(bookingStatsProvider);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _QuickRange {
  final String label;
  final DateTimeRange range;

  _QuickRange({required this.label, required this.range});
}
