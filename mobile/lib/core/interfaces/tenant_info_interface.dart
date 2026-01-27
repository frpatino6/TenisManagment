/// Interface for tenant information used across features
/// This interface decouples features from the tenant domain model
abstract class ITenantInfo {
  String get id;
  String get name;
  String? get logo;
  Map<String, dynamic>? get config;
}
