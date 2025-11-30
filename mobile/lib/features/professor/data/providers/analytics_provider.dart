import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/models/analytics_overview.dart';
import '../../domain/models/analytics_chart_data.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final analyticsOverviewProvider = FutureProvider.autoDispose
    .family<AnalyticsOverview, Map<String, String?>>((ref, filters) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getOverview(
        period: filters['period'] ?? 'month',
        serviceType: filters['serviceType'],
        status: filters['status'],
      );
    });

final analyticsRevenueProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getRevenueData(period: period);
    });

final analyticsBookingsProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getBookingsData(period: period);
    });

final analyticsStudentsProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getStudentsData(period: period);
    });

final analyticsFiltersProvider = Provider<Map<String, String?>>((ref) {
  return {'period': 'month', 'serviceType': null, 'status': null};
});

final analyticsRefreshProvider = Provider<int>((ref) => 0);

void refreshAnalytics(WidgetRef ref) {
  ref.invalidate(analyticsOverviewProvider);
  ref.invalidate(analyticsRevenueProvider);
  ref.invalidate(analyticsBookingsProvider);
  ref.invalidate(analyticsStudentsProvider);
}
