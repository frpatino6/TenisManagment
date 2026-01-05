import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tenant_service.dart';
import '../../features/tenant/domain/services/tenant_service.dart'
    as tenant_domain;
import '../../features/tenant/domain/models/tenant_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for TenantService singleton
final tenantServiceProvider = Provider<TenantService>((ref) {
  return TenantService();
});

/// Notifier for the current active tenant ID
/// State is managed here, not in the service
class CurrentTenantIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Always return null initially, will be updated by loadTenant
    // This prevents showing stale tenant data from previous user
    return null;
  }

  void update(String? tenantId) {
    state = tenantId;
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
    // Watch auth state - if user changes, clear tenant
    ref.listen(authStateProvider, (previous, next) {
      final previousUser = previous?.value;
      final nextUser = next.value;
      
      // If user changed (logout or different user login), clear tenant
      if (previousUser != null && (nextUser == null || previousUser.id != nextUser.id)) {
        state = const AsyncValue.loading();
        ref.read(currentTenantIdProvider.notifier).update(null);
        // Reload tenant for new user
        if (nextUser != null) {
          Future.microtask(() => loadTenant());
        } else {
          state = const AsyncValue.data(null);
        }
      } else if (nextUser != null && (previousUser == null || previousUser.id != nextUser.id)) {
        // New user logged in, load their tenant
        Future.microtask(() => loadTenant());
      }
    });
    
    // Start with loading to ensure router waits for tenant to load
    // This prevents showing select-tenant screen when tenant is still loading
    Future.microtask(() => loadTenant());
    return const AsyncValue.loading();
  }

  /// Load tenant from backend
  /// Always clears state first to prevent showing stale data from previous user
  Future<void> loadTenant() async {
    // CRITICAL: Always clear state FIRST to prevent showing stale data from previous user
    // This must happen before any async operations
    state = const AsyncValue.loading();
    ref.read(currentTenantIdProvider.notifier).update(null);

    try {
      final service = ref.read(tenantServiceProvider);

      // Always load from backend - service is stateless, no cache
      final tenantId = await service.loadTenant();
      state = AsyncValue.data(tenantId);

      if (tenantId != null && tenantId.isNotEmpty) {
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
      } else {
        ref.read(currentTenantIdProvider.notifier).update(null);
      }
    } catch (e, stackTrace) {
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
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
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
      state = const AsyncValue.data(null);
      ref.read(currentTenantIdProvider.notifier).update(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update tenant state directly without loading state
  /// This is used when updating from select-tenant screen to avoid navigation
  void updateTenantDirectly(String? tenantId) {
    state = AsyncValue.data(tenantId);
    ref.read(currentTenantIdProvider.notifier).update(tenantId);
  }

  /// Set tenant and save to backend without going through loading state
  /// Updates local state immediately, then saves to backend asynchronously
  /// This prevents router redirections while still persisting the selection
  Future<void> setTenantWithoutLoading(String tenantId) async {
    // Update local state immediately without loading
    state = AsyncValue.data(tenantId);
    ref.read(currentTenantIdProvider.notifier).update(tenantId);
    
    // Save to backend asynchronously without affecting state
    try {
      final service = ref.read(tenantServiceProvider);
      await service.setTenant(tenantId);
      // If successful, ensure state is still data (not loading)
      if (state.value != tenantId) {
        state = AsyncValue.data(tenantId);
      }
    } catch (e) {
      // If save fails, keep the local state
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
final currentTenantProvider = FutureProvider.autoDispose<TenantModel?>((
  ref,
) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    return null;
  }

  try {
    final service = ref.watch(tenant_domain.tenantDomainServiceProvider);
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
