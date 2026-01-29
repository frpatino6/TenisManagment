import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/interfaces/interfaces.dart';
import '../../domain/services/tenant_service.dart';

/// Implementation of ITenantProviderInterface using TenantService
class TenantProviderImpl implements ITenantProviderInterface {
  final TenantService _tenantService;

  TenantProviderImpl(this._tenantService);

  @override
  Future<List<ITenantInfo>> getAvailableTenants() async {
    final tenants = await _tenantService.getAvailableTenants();
    return tenants.cast<ITenantInfo>();
  }

  @override
  Future<List<ITenantInfo>> getMyTenants() async {
    final tenants = await _tenantService.getMyTenants();
    return tenants.cast<ITenantInfo>();
  }
}

/// Provider for TenantProviderImpl
final tenantProviderImplProvider = Provider<ITenantProviderInterface>((ref) {
  final tenantService = ref.watch(tenantDomainServiceProvider);
  return TenantProviderImpl(tenantService);
});
