/// Repository interface for pricing-related data operations
///
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class PricingRepository {
  /// Get professor's current pricing
  Future<Map<String, dynamic>> getMyPricing();

  /// Update professor's custom pricing
  Future<Map<String, dynamic>> updateMyPricing({
    double? individualClass,
    double? groupClass,
    double? courtRental,
  });

  /// Reset professor's pricing to base pricing
  Future<Map<String, dynamic>> resetMyPricing();
}
