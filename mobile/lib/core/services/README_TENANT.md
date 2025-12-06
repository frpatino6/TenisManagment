# Tenant Configuration - Usage Guide

## Overview

This module provides infrastructure for managing tenant (center) context in the app. It automatically adds the `X-Tenant-ID` header to all HTTP requests.

## Components

### 1. TenantService (`lib/core/services/tenant_service.dart`)

Singleton service for managing tenant persistence using SharedPreferences.

**Usage:**
```dart
final tenantService = TenantService();

// Load saved tenant
await tenantService.loadTenant();

// Set active tenant
await tenantService.setTenant('tenant-id-123');

// Get current tenant
final tenantId = tenantService.currentTenantId;

// Check if tenant is configured
if (tenantService.hasTenant) {
  // Tenant is configured
}

// Clear tenant
await tenantService.clearTenant();
```

### 2. TenantProvider (`lib/core/providers/tenant_provider.dart`)

Riverpod providers for tenant state management.

**Providers:**
- `tenantServiceProvider`: Provides TenantService singleton
- `currentTenantIdProvider`: Provides current tenant ID (String?)
- `hasTenantProvider`: Provides boolean indicating if tenant is configured
- `tenantNotifierProvider`: AsyncNotifier for tenant operations

**Usage:**
```dart
// Watch current tenant ID
final tenantId = ref.watch(currentTenantIdProvider);

// Check if tenant is configured
final hasTenant = ref.watch(hasTenantProvider);

// Set tenant
await ref.read(tenantNotifierProvider.notifier).setTenant('tenant-id');

// Load tenant from storage
await ref.read(tenantNotifierProvider.notifier).loadTenant();

// Clear tenant
await ref.read(tenantNotifierProvider.notifier).clearTenant();
```

### 3. AppHttpClient (`lib/core/services/http_client.dart`)

HTTP client wrapper that automatically adds `X-Tenant-ID` header to all requests.

**Usage:**
```dart
// In a service class
class MyService {
  final Ref _ref;
  
  MyService(this._ref);
  
  Future<void> fetchData() async {
    final client = AppHttpClient(_ref);
    
    final response = await client.get(
      Uri.parse('https://api.example.com/data'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    // X-Tenant-ID header is automatically added
  }
}

// Or using the provider
final httpClient = ref.read(appHttpClientProvider);
final response = await httpClient.get(Uri.parse('...'));
```

**Migration from direct `http` package:**

**Before:**
```dart
final response = await http.get(
  Uri.parse('$_baseUrl/endpoint'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

**After:**
```dart
final client = AppHttpClient(ref);
final response = await client.get(
  Uri.parse('$_baseUrl/endpoint'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
// X-Tenant-ID is automatically added
```

## Integration

The tenant service is automatically initialized when the app starts (see `main_common.dart`).

The router automatically redirects to `/select-tenant` if:
- User is authenticated
- No tenant is configured
- User tries to access protected routes

## Next Steps (TEN-93)

The `SelectTenantScreen` is currently a placeholder. In TEN-93, it will be fully implemented with:
- List of available tenants
- Search functionality
- QR code scanning
- Tenant selection logic

