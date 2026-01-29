import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../infrastructure/repositories/analytics_repository_impl.dart';
import '../../domain/models/analytics_overview.dart';
import '../../domain/models/analytics_chart_data.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl();
});

final analyticsOverviewProvider = FutureProvider.autoDispose
    .family<AnalyticsOverview, Map<String, String?>>((ref, filters) async {
      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getOverview(
        period: filters['period'] ?? 'month',
        serviceType: filters['serviceType'],
        status: filters['status'],
      );
    });

final analyticsRevenueProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getRevenueData(period: period);
    });

final analyticsBookingsProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getBookingsData(period: period);
    });

final analyticsStudentsProvider = FutureProvider.autoDispose
    .family<AnalyticsChartData, String>((ref, period) async {
      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getStudentsData(period: period);
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
