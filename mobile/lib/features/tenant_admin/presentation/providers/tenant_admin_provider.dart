import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/tenant_admin_service.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/models/tenant_metrics_model.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/models/tenant_court_model.dart';

// Note: tenantAdminServiceProvider is defined in domain/services/tenant_admin_service.dart
// We import it here to use in providers

/// Provider for tenant info
final tenantInfoProvider =
    FutureProvider.autoDispose<TenantConfigModel>((ref) async {
  final service = ref.watch(tenantAdminServiceProvider);
  return await service.getTenantInfo();
});

/// Provider for tenant metrics
final tenantMetricsProvider =
    FutureProvider.autoDispose<TenantMetricsModel>((ref) async {
  final service = ref.watch(tenantAdminServiceProvider);
  return await service.getMetrics();
});

/// Provider for professors list
final tenantProfessorsProvider =
    FutureProvider.autoDispose<List<TenantProfessorModel>>((ref) async {
  final service = ref.watch(tenantAdminServiceProvider);
  return await service.getProfessors();
});

/// Provider for courts list
final tenantCourtsProvider =
    FutureProvider.autoDispose<List<TenantCourtModel>>((ref) async {
  final service = ref.watch(tenantAdminServiceProvider);
  return await service.getCourts();
});

