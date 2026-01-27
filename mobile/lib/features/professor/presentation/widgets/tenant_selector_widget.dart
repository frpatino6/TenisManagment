import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/interfaces/interfaces.dart';
import '../../../../features/tenant/infrastructure/providers/tenant_provider_impl.dart';
import '../providers/professor_provider.dart';

/// Provider for professor's tenants
final professorTenantsProvider = FutureProvider.autoDispose<List<ITenantInfo>>((
  ref,
) async {
  final provider = ref.watch(tenantProviderImplProvider);
  // Use getMyTenants which will call the professor endpoint
  return provider.getMyTenants();
});

/// Widget to display and select tenant (center) for professors
/// Shows current tenant and allows switching between available tenants
class TenantSelectorWidget extends ConsumerWidget {
  const TenantSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentTenantId = ref.watch(currentTenantIdProvider);
    final AsyncValue<ITenantInfo?> currentTenant = ref.watch(currentTenantProvider);
    final AsyncValue<List<ITenantInfo>> tenantsAsync = ref.watch(professorTenantsProvider);

    return tenantsAsync.when(
      data: (tenants) {
        return _buildSelectorCard(
          context,
          ref,
          colorScheme,
          currentTenantId,
          currentTenant,
          tenantsAsync,
        );
      },
      loading: () => _buildSelectorCard(
        context,
        ref,
        colorScheme,
        currentTenantId,
        currentTenant,
        tenantsAsync,
      ),
      error: (error, stackTrace) => _buildSelectorCard(
        context,
        ref,
        colorScheme,
        currentTenantId,
        currentTenant,
        tenantsAsync,
      ),
    );
  }

  Widget _buildSelectorCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    String? currentTenantId,
    AsyncValue<ITenantInfo?> currentTenant,
    AsyncValue<List<ITenantInfo>> tenantsAsync,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: colorScheme.primary, size: 24),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿En qué centro trabajas hoy?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(4),
                      currentTenant.when(
                        data: (tenant) => Text(
                          tenant != null
                              ? 'Centro actual: ${tenant.name}'
                              : 'Selecciona un centro',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        loading: () => Text(
                          'Cargando...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        error: (error, stackTrace) => Text(
                          'Error al cargar centro',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () => _showTenantSelectorDialog(context, ref),
                ),
              ],
            ),
            const Gap(16),
            tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                      const Gap(12),
                      Text(
                        'No tienes centros asignados',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        'Debes ser invitado por un administrador del centro para poder trabajar allí.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                final currentTenantModel = tenants.firstWhere(
                  (t) => t.id == currentTenantId,
                  orElse: () => tenants.first,
                );

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (currentTenantModel.logo != null &&
                              currentTenantModel.logo!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                currentTenantModel.logo!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return TenantSelectorWidget._buildDefaultIcon(colorScheme);
                                },
                              ),
                            )
                          else
                            TenantSelectorWidget._buildDefaultIcon(colorScheme),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const Gap(4),
                                    Text(
                                      currentTenantModel.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(2),
                                Text(
                                  currentTenantModel.slug,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tenants.length > 1)
                            TextButton(
                              onPressed: () =>
                                  _showTenantSelectorDialog(context, ref),
                              child: Text(
                                'Cambiar',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Para unirte a otro centro, debes ser invitado por su administrador.',
                        style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Error al cargar centros: ${error.toString()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  static Widget _buildDefaultIcon(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primary.withValues(alpha: 0.2),
      ),
      child: Icon(Icons.business, color: colorScheme.primary, size: 20),
    );
  }

  void _showTenantSelectorDialog(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.read(professorTenantsProvider);
    final currentTenantId = ref.read(currentTenantIdProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Seleccionar Centro',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: tenantsAsync.when(
          data: (tenants) {
            if (tenants.isEmpty) {
              return const Text('No tienes centros asignados');
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tenants.length,
                itemBuilder: (context, index) {
                  final tenant = tenants[index];
                  final isSelected = tenant.id == currentTenantId;

                  return ListTile(
                    leading: tenant.logo != null && tenant.logo!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              tenant.logo!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  color: colorScheme.primary,
                                );
                              },
                            ),
                          )
                        : Icon(Icons.business, color: colorScheme.primary),
                    title: Text(
                      tenant.name,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(tenant.slug),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                    selected: isSelected,
                    selectedTileColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    onTap: () async {
                      if (!isSelected) {
                        await ref
                            .read(tenantNotifierProvider.notifier)
                            .setTenantWithoutLoading(tenant.id);

                        ref.invalidate(professorTenantsProvider);
                        ref.invalidate(professorInfoProvider);
                        ref.invalidate(professorStudentsProvider);
                        ref.invalidate(todayScheduleProvider);
                        ref.invalidate(weekScheduleProvider);
                        ref.invalidate(earningsStatsProvider);
                        ref.invalidate(professorSchedulesProvider);

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Centro cambiado a ${tenant.name}'),
                              duration: Timeouts.snackbarSuccess,
                            ),
                          );
                        }
                      } else {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Text(
            'Error al cargar centros: ${error.toString()}',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

}
