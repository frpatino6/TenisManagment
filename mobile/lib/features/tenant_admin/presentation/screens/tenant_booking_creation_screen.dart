import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/models/tenant_student_model.dart';
import '../../domain/models/tenant_debt_report_model.dart';
import '../providers/tenant_admin_provider.dart';

/// Screen for creating a new booking from the admin grid
class TenantBookingCreationScreen extends ConsumerStatefulWidget {
  final String courtId;
  final String courtName;
  final double courtPrice;
  final DateTime date;
  final DateTime startTime;

  const TenantBookingCreationScreen({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.courtPrice,
    required this.date,
    required this.startTime,
  });

  @override
  ConsumerState<TenantBookingCreationScreen> createState() =>
      _TenantBookingCreationScreenState();
}

class _TenantBookingCreationScreenState
    extends ConsumerState<TenantBookingCreationScreen> {
  final TextEditingController _searchController = TextEditingController();
  TenantStudentModel? _selectedStudent;
  int _durationMinutes = 60;
  String _paymentMethod = 'wallet'; // 'wallet' or 'external'
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime get _endTime =>
      widget.startTime.add(Duration(minutes: _durationMinutes));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentsAsync = ref.watch(tenantStudentsProvider);
    final debtAsync = ref.watch(debtReportProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Nueva Reserva')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(theme),
                      const Gap(16),
                      _buildStudentSearch(theme, studentsAsync, debtAsync),
                      const Gap(16),
                      _buildDurationSelector(theme),
                      const Gap(16),
                      _buildPaymentMethodSelector(theme),
                      if (_selectedStudent != null) ...[
                        const Gap(16),
                        _buildValidationWarnings(theme, debtAsync),
                      ],
                    ],
                  ),
                ),
              ),
              _buildBottomBar(theme),
            ],
          ),
          if (_isCreating)
            Positioned.fill(
              child: Container(
                color: colorScheme.surface.withValues(alpha: 0.85),
                child: const LoadingWidget(message: 'Creando reserva...'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_tennis, size: 20, color: colorScheme.primary),
                const Gap(8),
                Text(widget.courtName, style: theme.textTheme.titleLarge),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  DateFormat('EEEE d MMM yyyy', 'es').format(widget.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  '${DateFormat('HH:mm').format(widget.startTime)} - ${DateFormat('HH:mm').format(_endTime)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSearch(
    ThemeData theme,
    AsyncValue<TenantStudentsResponse> studentsAsync,
    AsyncValue<TenantDebtReportModel> debtAsync,
  ) {
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar Jugador', style: theme.textTheme.titleMedium),
            const Gap(12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (value) {
                ref.read(studentSearchProvider.notifier).set(value);
              },
            ),
            const Gap(12),
            studentsAsync.when(
              data: (response) {
                if (response.students.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No se encontraron jugadores',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: response.students.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = response.students[index];
                      final isSelected = _selectedStudent?.id == student.id;
                      final hasDebt = debtAsync.when(
                        data: (d) => d.debtors.any(
                          (debtor) =>
                              debtor.studentId == student.id &&
                              debtor.totalDebt > 0,
                        ),
                        loading: () => false,
                        error: (_, __) => false,
                      );

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: colorScheme.primaryContainer,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                student.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (hasDebt)
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: colorScheme.error,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          student.email,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '\$${student.balance.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: student.balance >= 0
                                ? theme.colorScheme.tertiary
                                : colorScheme.error,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStudent = student;
                          });
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: LoadingWidget(message: 'Cargando...')),
              ),
              error: (err, st) => SizedBox(
                height: 100,
                child: AppErrorWidget.fromError(
                  err,
                  onRetry: () => ref.invalidate(tenantStudentsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duración', style: theme.textTheme.titleMedium),
            const Gap(12),
            Row(
              children: [
                _durationChip(theme, 60, '60 min'),
                const Gap(8),
                _durationChip(theme, 90, '90 min'),
                const Gap(8),
                _durationChip(theme, 120, '120 min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(ThemeData theme, int minutes, String label) {
    final colorScheme = theme.colorScheme;
    final isSelected = _durationMinutes == minutes;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _durationMinutes = minutes),
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
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método de Pago', style: theme.textTheme.titleMedium),
            const Gap(12),
            _paymentMethodTile(
              theme,
              'wallet',
              'Monedero Digital',
              'Descontar del saldo del jugador',
              Icons.account_balance_wallet,
            ),
            const Gap(8),
            _paymentMethodTile(
              theme,
              'external',
              'Pagado Externamente',
              'Wompi, efectivo o transferencia',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodTile(
    ThemeData theme,
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final colorScheme = theme.colorScheme;
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 20, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationWarnings(
    ThemeData theme,
    AsyncValue<TenantDebtReportModel> debtAsync,
  ) {
    final warnings = <Widget>[];

    // Check debt
    final hasDebt = debtAsync.when(
      data: (d) => d.debtors.any(
        (debtor) =>
            debtor.studentId == _selectedStudent!.id && debtor.totalDebt > 0,
      ),
      loading: () => false,
      error: (_, __) => false,
    );

    if (hasDebt) {
      warnings.add(
        _warningCard(
          theme,
          'El jugador tiene deuda pendiente',
          Icons.warning_amber_rounded,
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
        ),
      );
    }

    // Check wallet balance when Monedero Digital is selected
    if (_paymentMethod == 'wallet') {
      final price = (widget.courtPrice / 60) * _durationMinutes;
      if (_selectedStudent!.balance < price) {
        warnings.add(
          _warningCard(
            theme,
            'Saldo insuficiente en el monedero (\$${_selectedStudent!.balance.toStringAsFixed(0)}). '
            'El costo es \$${price.toStringAsFixed(0)}',
            Icons.error_outline,
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer,
          ),
        );
      }
    }

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Column(
      children: warnings
          .map(
            (w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
          )
          .toList(),
    );
  }

  Widget _warningCard(
    ThemeData theme,
    String message,
    IconData icon,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const Gap(12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final price = (widget.courtPrice / 60) * _durationMinutes;
    final hasEnoughBalance = _selectedStudent == null
        ? false
        : _selectedStudent!.balance >= price;
    final walletBlocked =
        _paymentMethod == 'wallet' &&
        _selectedStudent != null &&
        !hasEnoughBalance;
    final canCreate =
        _selectedStudent != null && !_isCreating && !walletBlocked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canCreate ? _createBooking : null,
          child: const Text('Confirmar Reserva'),
        ),
      ),
    );
  }

  Future<void> _createBooking() async {
    if (_selectedStudent == null) return;

    setState(() => _isCreating = true);

    try {
      final price = (widget.courtPrice / 60) * _durationMinutes;

      final repository = ref.read(tenantAdminRepositoryProvider);
      await repository.createBooking(
        courtId: widget.courtId,
        studentId: _selectedStudent!.id,
        startTime: widget.startTime,
        endTime: _endTime,
        paymentStatus: _paymentMethod == 'wallet' ? 'pending' : 'paid',
        paymentMethod: _paymentMethod == 'wallet' ? 'wallet' : 'cash',
        price: price,
        serviceType: 'court_rental',
      );

      ref.invalidate(adminCourtGridDataProvider(widget.date));
      ref.invalidate(tenantBookingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reserva creada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
