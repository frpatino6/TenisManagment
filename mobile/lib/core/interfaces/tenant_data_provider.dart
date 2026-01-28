import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tenant_info_interface.dart';

/// Interface for tenant data operations used across features
/// This interface decouples features from the tenant domain implementation
/// Features like booking should depend only on this interface, not on tenant domain
abstract class TenantDataProvider {
  /// Get the current active tenant information
  /// Returns null if no tenant is configured
  Future<ITenantInfo?> getCurrentTenant();

  /// Get the current active tenant ID
  /// Returns null if no tenant is configured
  String? getCurrentTenantId();

  /// Get all available tenants for selection
  /// Returns all active tenants that can be selected
  Future<List<ITenantInfo>> getAvailableTenants();

  /// Get list of tenants for the current user
  /// For students: returns tenants where they have bookings
  /// For professors: returns tenants where they work
  Future<List<ITenantInfo>> getMyTenants();

  /// Check if a tenant is currently configured
  bool hasTenant();

  /// Get the tenant state as AsyncValue
  /// Used for watching tenant loading/error states
  AsyncValue<String?> getTenantState();

  /// Set the active tenant
  /// Updates the tenant ID and saves it to backend
  Future<void> setTenant(String tenantId);

  /// Update tenant ID directly without loading state
  /// Used for immediate UI updates
  void updateTenantId(String? tenantId);

  /// Refresh tenant data
  /// Forces a reload of tenant information from backend
  Future<void> refreshTenant();
}
