import 'tenant_info_interface.dart';

/// Interface for tenant provider operations
/// This interface decouples features from the tenant domain service
abstract class ITenantProviderInterface {
  /// Get all available tenants for selection
  Future<List<ITenantInfo>> getAvailableTenants();

  /// Get list of tenants for the current user
  /// For students: returns tenants where they have bookings
  /// For professors: returns tenants where they work
  Future<List<ITenantInfo>> getMyTenants();
}
