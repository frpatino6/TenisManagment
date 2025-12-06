import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tenant_service.dart';
import '../../features/tenant/domain/services/tenant_service.dart' as tenant_domain;
import '../../features/tenant/domain/models/tenant_model.dart';

/// Provider for TenantService singleton
final tenantServiceProvider = Provider<TenantService>((ref) {
  return TenantService();
});

/// Notifier for the current active tenant ID
class CurrentTenantIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Initialize by reading from service
    final service = ref.read(tenantServiceProvider);
    final tenantId = service.currentTenantId;
    
    // If service has tenant but state is null, update state
    if (tenantId != null && tenantId.isNotEmpty && state != tenantId) {
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() => state = tenantId);
    }
    
    return tenantId;
  }

  void update(String? tenantId) {
    state = tenantId;
  }
  
  /// Refresh from service
  void refresh() {
    final service = ref.read(tenantServiceProvider);
    state = service.currentTenantId;
  }
}

/// Provider for the current active tenant ID
/// Returns null if no tenant is configured
final currentTenantIdProvider =
    NotifierProvider<CurrentTenantIdNotifier, String?>(() {
      return CurrentTenantIdNotifier();
    });

/// Provider to check if a tenant is configured
final hasTenantProvider = Provider<bool>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  return tenantId != null && tenantId.isNotEmpty;
});

/// Notifier for managing tenant state
class TenantNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    final service = ref.read(tenantServiceProvider);
    final tenantId = service.currentTenantId;
    return AsyncValue.data(tenantId);
  }

  /// Load tenant from storage
  Future<void> loadTenant() async {
    print('[TenantNotifier] loadTenant() called');
    state = const AsyncValue.loading();
    try {
      final service = ref.read(tenantServiceProvider);
      
      // Ensure service is initialized by calling loadTenant which initializes _prefs if needed
      // loadTenant() already handles _prefs ??= await SharedPreferences.getInstance()
      
      print('[TenantNotifier] Loading tenant from service...');
      final tenantId = await service.loadTenant();
      print('[TenantNotifier] Loaded tenant ID: $tenantId');
      state = AsyncValue.data(tenantId);
      // Update the state provider as well - ensure it's updated
      if (tenantId != null && tenantId.isNotEmpty) {
        print('[TenantNotifier] Updating currentTenantIdProvider with: $tenantId');
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
        // Also refresh to ensure consistency
        ref.read(currentTenantIdProvider.notifier).refresh();
      } else {
        print('[TenantNotifier] No tenant ID found, updating to null');
        ref.read(currentTenantIdProvider.notifier).update(null);
      }
    } catch (e, stackTrace) {
      print('[TenantNotifier] Error loading tenant: $e');
      print('[TenantNotifier] Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      ref.read(currentTenantIdProvider.notifier).update(null);
    }
  }

  /// Set the active tenant
  Future<void> setTenant(String tenantId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(tenantServiceProvider);
      final success = await service.setTenant(tenantId);
      if (success) {
        state = AsyncValue.data(tenantId);
        // Update the state provider as well - ensure it's updated
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
        // Also refresh to ensure consistency
        ref.read(currentTenantIdProvider.notifier).refresh();
      } else {
        throw Exception('Failed to save tenant ID');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ref.read(currentTenantIdProvider.notifier).update(null);
    }
  }

  /// Clear the active tenant
  Future<void> clearTenant() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(tenantServiceProvider);
      final success = await service.clearTenant();
      if (success) {
        state = const AsyncValue.data(null);
        // Update the state provider as well
        ref.read(currentTenantIdProvider.notifier).update(null);
      } else {
        throw Exception('Failed to clear tenant ID');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for TenantNotifier
final tenantNotifierProvider =
    NotifierProvider<TenantNotifier, AsyncValue<String?>>(() {
      return TenantNotifier();
    });

/// Provider to get the current tenant model (with name, etc.)
/// This provider fetches the tenant details based on the current tenant ID
final currentTenantProvider = FutureProvider.autoDispose<TenantModel?>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    return null;
  }

  try {
    final service = ref.watch(tenant_domain.tenantDomainServiceProvider);
    // Get all available tenants and find the one matching the current ID
    final tenants = await service.getAvailableTenants();
    return tenants.firstWhere(
      (tenant) => tenant.id == tenantId,
      orElse: () => throw Exception('Centro no encontrado'),
    );
  } catch (e) {
    // If getAvailableTenants fails, try getMyTenants
    try {
      final service = ref.watch(tenant_domain.tenantDomainServiceProvider);
      final tenants = await service.getMyTenants();
      return tenants.firstWhere(
        (tenant) => tenant.id == tenantId,
        orElse: () => throw Exception('Centro no encontrado'),
      );
    } catch (_) {
      rethrow;
    }
  }
});
