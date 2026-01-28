import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/interfaces/interfaces.dart';
import '../../../../core/providers/tenant_provider.dart' as core_tenant_provider;
import '../../domain/services/tenant_service.dart';
import '../adapters/tenant_data_provider_impl.dart';

/// Implementation of ITenantProviderInterface using TenantService
class TenantProviderImpl implements ITenantProviderInterface {
  final TenantService _tenantService;

  TenantProviderImpl(this._tenantService);

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
}

/// Provider for ITenantProviderInterface
final tenantProviderImplProvider = Provider<ITenantProviderInterface>((ref) {
  final tenantService = ref.watch(tenantDomainServiceProvider);
  return TenantProviderImpl(tenantService);
});

/// Provider for TenantDataProvider
/// This is the main provider that features should use to access tenant data
/// It decouples features from tenant domain implementation
final tenantDataProvider = Provider<TenantDataProvider>((ref) {
  return ref.watch(tenantDataProviderImplProvider);
});

/// Implementation of core's tenantDataProviderProvider
/// This makes the TenantDataProvider available to core without core importing tenant implementation
/// This provider provides the actual implementation for core's tenantDataProviderProvider
/// Note: This provider should be imported in the app's main provider scope
/// It will override core's UnimplementedError with the actual implementation
final tenantDataProviderProvider = Provider<TenantDataProvider>((ref) {
  return ref.watch(tenantDataProviderImplProvider);
});
