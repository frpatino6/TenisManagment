import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tenant_service.dart';
import '../interfaces/interfaces.dart';
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
    // Watch auth notifier state - if user changes, clear tenant
    // Fix: Listen to authNotifierProvider instead of authStateProvider to stay in sync with Router
    ref.listen(authNotifierProvider, (previous, next) {
      final previousUser = previous?.value;
      final nextUser = next.value;

      // If user changed (logout or different user login), clear tenant
      if (previousUser != null &&
          (nextUser == null || previousUser.id != nextUser.id)) {
        state = const AsyncValue.loading();
        ref.read(currentTenantIdProvider.notifier).update(null);
        // Reload tenant for new user
        if (nextUser != null) {
          Future.microtask(() => loadTenant());
        } else {
          state = const AsyncValue.data(null);
        }
      } else if (nextUser != null &&
          (previousUser == null || previousUser.id != nextUser.id)) {
        // New user logged in, load their tenant
        // Fix: Set state to loading immediately to prevent UI flicker
        state = const AsyncValue.loading();
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

      // Fix: Update ID before state to preventing router from seeing loading=false + NoTenant
      if (tenantId != null && tenantId.isNotEmpty) {
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
      } else {
        ref.read(currentTenantIdProvider.notifier).update(null);
      }

      state = AsyncValue.data(tenantId);
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
        // Fix: Update ID before state
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
        state = AsyncValue.data(tenantId);
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

/// Provider for TenantDataProvider interface
/// This provider is defined by tenant feature and exported via tenant_providers.dart
/// Core declares it here as a placeholder that can be overridden
/// Features should import tenant_providers.dart to get access to the actual implementation
/// The actual provider is defined in tenant/infrastructure/providers/tenant_provider_impl.dart
final tenantDataProviderProvider = Provider<TenantDataProvider>((ref) {
  throw UnimplementedError(
    'tenantDataProviderProvider must be provided by tenant feature. '
    'Import tenant_providers.dart in your app\'s provider scope.',
  );
});

/// Provider to get the current tenant model (with name, etc.)
/// This provider fetches the tenant details based on the current tenant ID
/// Returns ITenantInfo to decouple from tenant domain model
/// Uses TenantDataProvider interface - implementation is provided by tenant feature
/// Note: This provider depends on tenantDataProviderProvider which must be provided by tenant feature
/// The tenant feature should export its tenantDataProviderProvider via tenant_providers.dart
/// To use this provider, you must import tenant feature providers in your app's provider scope:
/// import 'package:.../features/tenant/infrastructure/providers/tenant_providers.dart';
final currentTenantProvider = FutureProvider.autoDispose<ITenantInfo?>((
  ref,
) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    return null;
  }

  // Use TenantDataProvider interface - implementation is provided by tenant feature
  // This avoids direct dependency on tenant/infrastructure
  // The tenant feature must provide tenantDataProviderProvider via tenant_providers.dart
  // We use a try-catch to handle the case where tenant feature is not available
  try {
    // This provider is defined in tenant feature and exported via tenant_providers.dart
    // Core can use it without importing tenant implementation directly
    // Features that use this should import tenant_providers.dart in their provider scope
    final tenantDataProvider = ref.watch(tenantDataProviderProvider);
    return tenantDataProvider.getCurrentTenant();
  } catch (e) {
    // If tenantDataProviderProvider is not provided, return null
    // This allows core to work without tenant feature (for testing, etc.)
    return null;
  }
});
