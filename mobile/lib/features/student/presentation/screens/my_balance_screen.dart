import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../payment/presentation/widgets/payment_dialog.dart';
import '../../../../core/utils/currency_utils.dart';
import '../providers/student_provider.dart';

import '../../../../core/providers/tenant_provider.dart';
import '../../../../core/logging/logger.dart';

class MyBalanceScreen extends ConsumerStatefulWidget {
  const MyBalanceScreen({super.key});

  @override
  ConsumerState<MyBalanceScreen> createState() => _MyBalanceScreenState();
}

class _MyBalanceScreenState extends ConsumerState<MyBalanceScreen> {
  double? _previousBalance;
  final _logger = AppLogger.tag('MyBalanceScreen');

  bool get _hasWompiConfigured {
    final tenant = ref.read(currentTenantProvider).value;
    final config = tenant?.config;
    _logger.info('DEBUG: Tenant ${tenant?.name} config: $config');
    if (config == null) return false;

    // Check for nested structure: config -> payments -> wompi -> pubKey
    if (config.containsKey('payments')) {
      final payments = config['payments'];
      if (payments is Map) {
        final wompi = payments['wompi'];
        if (wompi is Map) {
          final pubKey = wompi['pubKey'];
          if (pubKey != null && pubKey.toString().trim().isNotEmpty) {
            _logger.info('DEBUG: Found Wompi key in nested config');
            return true;
          }
        }
      }
    }

    // Fallback: Check for flat structure (backward compatibility)
    bool isValid(String key) {
      if (!config.containsKey(key)) return false;
      final value = config[key];
      return value != null && value.toString().trim().isNotEmpty;
    }

    final hasKey = isValid('wompi_public_key') || isValid('wompiPublicKey');
    _logger.info('DEBUG: Has Wompi config? (flat check): $hasKey');
    return hasKey;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Refresh tenant data to ensure we have the latest config (e.g. Wompi keys)
      final _ = ref.refresh(currentTenantProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentInfoAsync = ref.watch(studentInfoProvider);
    final isSyncing = ref.watch(balanceSyncProvider);
    // Watch tenant to rebuild when config refreshes
    ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Balance',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentInfoProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          studentInfoAsync.when(
            data: (studentInfo) {
              final currentBalance =
                  (studentInfo['balance'] as num?)?.toDouble() ?? 0.0;

              // Hide overlay if balance changed after syncing
              if (isSyncing &&
                  _previousBalance != null &&
                  currentBalance != _previousBalance) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      ref.read(balanceSyncProvider.notifier).stop();
                      _previousBalance = currentBalance;
                    });
                  }
                });
              }

              return _buildBalanceContent(context, studentInfo);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(context, error.toString()),
          ),
          if (isSyncing)
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
                      const Gap(20),
                      Text(
                        'Actualizando saldo...',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Estamos sincronizando con el servidor',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const Gap(24),
          Text(
            'Error al cargar información',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(studentInfoProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceContent(
    BuildContext context,
    Map<String, dynamic> studentInfo,
  ) {
    final balance = (studentInfo['balance'] as num?)?.toDouble() ?? 0.0;
    final totalSpent = (studentInfo['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final totalClasses = studentInfo['totalClasses'] as int? ?? 0;
    final totalPayments = studentInfo['totalPayments'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(
                context,
                balance,
                totalSpent,
                totalClasses,
                totalPayments,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const Gap(24),

          Text(
                'Estadísticas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideX(begin: -0.2, end: 0),

          const Gap(16),

          _buildStatsGrid(
                context,
                balance,
                totalSpent,
                totalClasses,
                totalPayments,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 600.ms)
              .slideY(begin: 0.2, end: 0),

          const Gap(24),

          Text(
                'Acciones',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 800.ms)
              .slideX(begin: -0.2, end: 0),

          const Gap(16),

          _buildActionButtons(context)
              .animate()
              .fadeIn(duration: 400.ms, delay: 1000.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double totalSpent,
    int totalClasses,
    int totalPayments,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Disponible',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        CurrencyUtils.format(balance),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Clases',
                    totalClasses.toString(),
                    Icons.sports_tennis,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pagos',
                    totalPayments.toString(),
                    Icons.payment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Gap(8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    double balance,
    double totalSpent,
    int totalClasses,
    int totalPayments,
  ) {
    final averagePerClass = totalClasses > 0 ? totalSpent / totalClasses : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          context,
          'Promedio por Clase',
          CurrencyUtils.format(averagePerClass),
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Total de Clases',
          totalClasses.toString(),
          Icons.sports_tennis,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Pagos Realizados',
          totalPayments.toString(),
          Icons.payment,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Inversión Total',
          CurrencyUtils.format(totalSpent),
          Icons.account_balance_wallet,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Gap(8),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(4),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (_hasWompiConfigured)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showTopUpDialog(context),
              icon: const Icon(Icons.add_card),
              label: const Text('Recargar Saldo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_hasWompiConfigured) const Gap(12),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/book-class'),
            icon: const Icon(Icons.book_online),
            label: const Text('Reservar Nueva Clase'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/my-bookings'),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Ver Mis Reservas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTopUpDialog(BuildContext context) async {
    // Capture current balance before payment
    final currentInfo = ref.read(studentInfoProvider).value;
    final currentBalance = (currentInfo?['balance'] as num?)?.toDouble() ?? 0.0;

    final paymentStarted = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentDialog(
        onPaymentStart: () {
          if (!mounted) return;
          setState(() {
            _previousBalance = currentBalance;
          });
          ref.read(balanceSyncProvider.notifier).start();
        },
        onPaymentComplete: () {
          ref.invalidate(studentInfoProvider);
        },
      ),
    );

    if (mounted && paymentStarted == true) {
      setState(() {
        _previousBalance = currentBalance;
      });
      ref.read(balanceSyncProvider.notifier).start();
      ref.invalidate(studentInfoProvider);
    }
  }
}
