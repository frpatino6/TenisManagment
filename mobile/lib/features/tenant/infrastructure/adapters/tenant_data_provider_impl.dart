import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/interfaces/interfaces.dart';
import '../../domain/services/tenant_service.dart';
import '../../../../core/providers/tenant_provider.dart' as core_tenant_provider;

/// Implementation of TenantDataProvider using tenant domain services
/// This adapter bridges the gap between core interfaces and tenant domain
class TenantDataProviderImpl implements TenantDataProvider {
  final Ref _ref;
  final TenantService _tenantService;

  TenantDataProviderImpl(
    this._ref,
    this._tenantService,
  );

  @override
  Future<ITenantInfo?> getCurrentTenant() async {
    final tenantId = getCurrentTenantId();
    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }

    try {
      final tenants = await getAvailableTenants();
      try {
        return tenants.firstWhere(
          (tenant) => tenant.id == tenantId,
        );
      } catch (_) {
        final myTenants = await getMyTenants();
        return myTenants.firstWhere(
          (tenant) => tenant.id == tenantId,
          orElse: () => throw Exception('Centro no encontrado'),
        );
      }
    } catch (_) {
      return null;
    }
  }

  @override
  String? getCurrentTenantId() {
    return _ref.read(core_tenant_provider.currentTenantIdProvider);
  }

  @override
  Future<List<ITenantInfo>> getAvailableTenants() async {
    final tenants = await _tenantService.getAvailableTenants();
    return tenants;
  }

  @override
  Future<List<ITenantInfo>> getMyTenants() async {
    final tenants = await _tenantService.getMyTenants();
    return tenants;
  }

  @override
  bool hasTenant() {
    return _ref.read(core_tenant_provider.hasTenantProvider);
  }

  @override
  AsyncValue<String?> getTenantState() {
    return _ref.read(core_tenant_provider.tenantNotifierProvider);
  }

  @override
  Future<void> setTenant(String tenantId) async {
    await _ref.read(core_tenant_provider.tenantNotifierProvider.notifier).setTenant(tenantId);
  }

  @override
  void updateTenantId(String? tenantId) {
    _ref.read(core_tenant_provider.currentTenantIdProvider.notifier).update(tenantId);
  }

  @override
  Future<void> refreshTenant() async {
    await _ref.read(core_tenant_provider.tenantNotifierProvider.notifier).loadTenant();
  }
}

/// Provider for TenantDataProvider implementation
final tenantDataProviderImplProvider = Provider<TenantDataProvider>((ref) {
  final tenantService = ref.watch(tenantDomainServiceProvider);
  return TenantDataProviderImpl(ref, tenantService);
});
