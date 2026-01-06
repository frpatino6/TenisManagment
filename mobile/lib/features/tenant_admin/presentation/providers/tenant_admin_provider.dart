import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tenant_metrics_model.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/services/tenant_admin_service.dart';
import '../../../../core/providers/tenant_provider.dart';

/// Provider for TenantAdminService
final tenantAdminServiceProvider = Provider<TenantAdminService>((ref) {
  return TenantAdminService(ref: ref);
});

/// Provider for tenant metrics
/// Waits for tenant to be loaded before fetching metrics (requires X-Tenant-ID header)
final tenantMetricsProvider = FutureProvider<TenantMetricsModel>((ref) async {
  // Wait for tenant to be loaded - watch currentTenantIdProvider
  final tenantId = ref.watch(currentTenantIdProvider);

  // If tenant is not loaded yet, throw error to retry later
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }

  final service = ref.read(tenantAdminServiceProvider);
  return await service.getMetrics();
});

/// Provider for tenant configuration/info
final tenantInfoProvider = FutureProvider<TenantConfigModel>((ref) async {
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getTenantInfo();
});

/// Provider for list of professors
/// Waits for tenant to be loaded before fetching professors (requires X-Tenant-ID header)
final tenantProfessorsProvider = FutureProvider<List<TenantProfessorModel>>((
  ref,
) async {
  // Wait for tenant to be loaded - watch currentTenantIdProvider
  final tenantId = ref.watch(currentTenantIdProvider);

  // If tenant is not loaded yet, throw error to retry later
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }

  final service = ref.read(tenantAdminServiceProvider);
  return await service.getProfessors();
});
