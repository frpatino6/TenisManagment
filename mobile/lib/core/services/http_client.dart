import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tenant_provider.dart';

/// HTTP Client wrapper that automatically adds X-Tenant-ID header
/// to all requests based on the current tenant configuration
///
/// Usage:
/// ```dart
/// final client = AppHttpClient(ref);
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// ```
class AppHttpClient {
  final Ref _ref;

  AppHttpClient(this._ref);

  /// Get the current tenant ID from the provider or service
  String? _getTenantId() {
    try {
      // First try to get from provider
      final tenantId = _ref.read(currentTenantIdProvider);
      if (tenantId != null && tenantId.isNotEmpty) {
        return tenantId;
      }
      
      // If provider returns null, try to get directly from service
      final service = _ref.read(tenantServiceProvider);
      final serviceTenantId = service.currentTenantId;
      if (serviceTenantId != null && serviceTenantId.isNotEmpty) {
        // Update provider state
        _ref.read(currentTenantIdProvider.notifier).update(serviceTenantId);
        return serviceTenantId;
      }
      
      return null;
    } catch (e) {
      // Provider not available, try service directly
      try {
        final service = _ref.read(tenantServiceProvider);
        return service.currentTenantId;
      } catch (_) {
        return null;
      }
    }
  }

  /// Build headers with tenant ID if available
  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    final tenantId = _getTenantId();
    if (tenantId != null && tenantId.isNotEmpty) {
      headers['X-Tenant-ID'] = tenantId;
    }

    return headers;
  }

  /// GET request with automatic X-Tenant-ID header
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return http.get(
      url,
      headers: _buildHeaders(headers),
    );
  }

  /// POST request with automatic X-Tenant-ID header
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.post(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  /// PUT request with automatic X-Tenant-ID header
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.put(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  /// PATCH request with automatic X-Tenant-ID header
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.patch(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  /// DELETE request with automatic X-Tenant-ID header
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.delete(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  /// HEAD request with automatic X-Tenant-ID header
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return http.head(
      url,
      headers: _buildHeaders(headers),
    );
  }
}

/// Provider for AppHttpClient
/// Usage in services:
/// ```dart
/// final httpClient = ref.read(appHttpClientProvider);
/// final response = await httpClient.get(Uri.parse('...'));
/// ```
final appHttpClientProvider = Provider<AppHttpClient>((ref) {
  return AppHttpClient(ref);
});

