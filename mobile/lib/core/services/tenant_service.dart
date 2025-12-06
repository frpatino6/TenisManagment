import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing tenant (center) configuration
/// Handles persistence and retrieval of the active tenant ID
/// Singleton pattern for global access
class TenantService {
  static const String _tenantIdKey = 'active_tenant_id';
  static const String _lastTenantIdKey = 'last_tenant_id';

  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  String? _currentTenantId;
  SharedPreferences? _prefs;

  /// Initialize the service and load the saved tenant ID
  /// Should be called at app startup
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await loadTenant();
  }

  /// Load the saved tenant ID from SharedPreferences
  /// Returns the tenant ID if found, null otherwise
  Future<String?> loadTenant() async {
    print('[TenantService] loadTenant() called');
    _prefs ??= await SharedPreferences.getInstance();
    print('[TenantService] SharedPreferences initialized');

    final tenantId = _prefs!.getString(_tenantIdKey);
    print('[TenantService] Loaded tenant ID from SharedPreferences: $tenantId');
    _currentTenantId = tenantId;
    print('[TenantService] _currentTenantId set to: $_currentTenantId');
    return tenantId;
  }

  /// Get the current active tenant ID
  /// Returns null if no tenant is set
  String? get currentTenantId => _currentTenantId;

  /// Check if a tenant is currently configured
  bool get hasTenant =>
      _currentTenantId != null && _currentTenantId!.isNotEmpty;

  /// Set the active tenant ID
  /// Saves to SharedPreferences and updates the current value
  /// Returns true if successful, false otherwise
  Future<bool> setTenant(String tenantId) async {
    _prefs ??= await SharedPreferences.getInstance();

    try {
      // Save as current tenant
      final saved = await _prefs!.setString(_tenantIdKey, tenantId);
      if (saved) {
        // Also save as last tenant for quick access
        await _prefs!.setString(_lastTenantIdKey, tenantId);
        _currentTenantId = tenantId;
      }
      return saved;
    } catch (e) {
      return false;
    }
  }

  /// Clear the active tenant ID
  /// Useful when logging out or switching accounts
  Future<bool> clearTenant() async {
    _prefs ??= await SharedPreferences.getInstance();

    try {
      final cleared = await _prefs!.remove(_tenantIdKey);
      if (cleared) {
        _currentTenantId = null;
      }
      return cleared;
    } catch (e) {
      return false;
    }
  }

  /// Get the last tenant ID used (for quick selection)
  Future<String?> getLastTenantId() async {
    _prefs ??= await SharedPreferences.getInstance();

    return _prefs!.getString(_lastTenantIdKey);
  }
}
