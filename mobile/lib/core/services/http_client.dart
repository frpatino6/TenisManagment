import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tenant_provider.dart';
import '../constants/timeouts.dart';
import '../exceptions/exceptions.dart';

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

  /// Get the current tenant ID from the provider
  /// Service is stateless, so we only use the provider
  String? _getTenantId() {
    try {
      // Get from provider (which loads from backend)
      final tenantId = _ref.read(currentTenantIdProvider);
      if (tenantId != null && tenantId.isNotEmpty) {
        return tenantId;
      }
      return null;
    } catch (e) {
      // Provider not available
      return null;
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

  /// GET request with automatic X-Tenant-ID header and timeout
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return http
        .get(url, headers: _buildHeaders(headers))
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );
  }

  /// POST request with automatic X-Tenant-ID header and timeout
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    return http
        .post(
          url,
          headers: _buildHeaders(headers),
          body: body,
          encoding: encoding,
        )
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );
  }

  /// PUT request with automatic X-Tenant-ID header and timeout
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    return http
        .put(
          url,
          headers: _buildHeaders(headers),
          body: body,
          encoding: encoding,
        )
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );
  }

  /// PATCH request with automatic X-Tenant-ID header and timeout
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    return http
        .patch(
          url,
          headers: _buildHeaders(headers),
          body: body,
          encoding: encoding,
        )
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );
  }

  /// DELETE request with automatic X-Tenant-ID header and timeout
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    return http
        .delete(
          url,
          headers: _buildHeaders(headers),
          body: body,
          encoding: encoding,
        )
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );
  }

  /// HEAD request with automatic X-Tenant-ID header and timeout
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return http
        .head(url, headers: _buildHeaders(headers))
        .timeout(
          timeout ?? Timeouts.httpRequest,
          onTimeout: () {
            throw NetworkException.timeout();
          },
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
