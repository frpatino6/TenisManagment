import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tenant_service.dart';

/// Provider for TenantService singleton
final tenantServiceProvider = Provider<TenantService>((ref) {
  return TenantService();
});

/// Notifier for the current active tenant ID
class CurrentTenantIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final service = ref.read(tenantServiceProvider);
    return service.currentTenantId;
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
    final service = ref.read(tenantServiceProvider);
    final tenantId = service.currentTenantId;
    return AsyncValue.data(tenantId);
  }

  /// Load tenant from storage
  Future<void> loadTenant() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(tenantServiceProvider);
      final tenantId = await service.loadTenant();
      state = AsyncValue.data(tenantId);
      // Update the state provider as well
      ref.read(currentTenantIdProvider.notifier).update(tenantId);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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
        // Update the state provider as well
        ref.read(currentTenantIdProvider.notifier).update(tenantId);
      } else {
        throw Exception('Failed to save tenant ID');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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
