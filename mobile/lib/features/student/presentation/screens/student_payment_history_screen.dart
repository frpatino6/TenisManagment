import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_utils.dart';
import '../providers/student_provider.dart';
import '../../domain/models/student_payment_model.dart';

class StudentPaymentHistoryScreen extends ConsumerStatefulWidget {
  const StudentPaymentHistoryScreen({super.key});

  @override
  ConsumerState<StudentPaymentHistoryScreen> createState() =>
      _StudentPaymentHistoryScreenState();
}

class _StudentPaymentHistoryScreenState
    extends ConsumerState<StudentPaymentHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      paymentHistoryProvider((
        from: _fromDate,
        to: _toDate,
        status: _statusFilter,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Pagos',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_fromDate != null || _toDate != null || _statusFilter != null)
            _buildActiveFilters(),
          Expanded(
            child: historyAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) =>
                      _buildPaymentItem(payments[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 16),
          const Gap(8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_fromDate != null || _toDate != null)
                    _buildFilterChip(
                      'Rango de fechas',
                      onClear: () => setState(() {
                        _fromDate = null;
                        _toDate = null;
                      }),
                    ),
                  if (_statusFilter != null)
                    _buildFilterChip(
                      _statusFilter == 'paid' ? 'Aprobados' : 'Pendientes',
                      onClear: () => setState(() => _statusFilter = null),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _fromDate = null;
              _toDate = null;
              _statusFilter = null;
            }),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onClear}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onClear,
        deleteIcon: const Icon(Icons.close, size: 14),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPaymentItem(StudentPaymentModel payment) {
    final isPaid = payment.status == 'paid';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPaid ? Colors.green : Colors.orange).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.description,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(payment.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Gap(4),
                  Text(
                    'Centro: ${payment.tenantName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.format(payment.amount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPaid ? Colors.green : Colors.orange).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPaid ? 'APROBADO' : 'PENDIENTE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
          const Gap(16),
          Text(
            'No se encontraron pagos',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_fromDate != null || _toDate != null || _statusFilter != null)
            TextButton(
              onPressed: () => setState(() {
                _fromDate = null;
                _toDate = null;
                _statusFilter = null;
              }),
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar Pagos',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(24),
                  Text(
                    'Estado',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      _buildFilterOption(
                        'Todos',
                        null,
                        _statusFilter,
                        (val) => setModalState(() => _statusFilter = val),
                      ),
                      const Gap(12),
                      _buildFilterOption(
                        'Aprobados',
                        'paid',
                        _statusFilter,
                        (val) => setModalState(() => _statusFilter = val),
                      ),
                      const Gap(12),
                      _buildFilterOption(
                        'Pendientes',
                        'pending',
                        _statusFilter,
                        (val) => setModalState(() => _statusFilter = val),
                      ),
                    ],
                  ),
                  const Gap(24),
                  Text(
                    'Rango de Fechas',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => _fromDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _fromDate == null
                                ? 'Desde'
                                : DateFormat('dd/MM/yy').format(_fromDate!),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => _toDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _toDate == null
                                ? 'Hasta'
                                : DateFormat('dd/MM/yy').format(_toDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                  const Gap(12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    String label,
    String? value,
    String? groupValue,
    Function(String?) onChanged,
  ) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : null,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
