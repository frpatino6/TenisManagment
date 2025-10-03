import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/models/analytics_overview.dart';
import '../../domain/models/analytics_chart_data.dart';

// Notifiers para manejar el estado
class AnalyticsFiltersNotifier extends StateNotifier<Map<String, String?>> {
  AnalyticsFiltersNotifier()
    : super({'period': 'month', 'serviceType': null, 'status': null});

  void updateFilters(Map<String, String?> newFilters) {
    state = newFilters;
  }
}

class AnalyticsRefreshNotifier extends StateNotifier<int> {
  AnalyticsRefreshNotifier() : super(0);

  void refresh() {
    state++;
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final analyticsOverviewProvider =
    FutureProvider.family<AnalyticsOverview, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getOverview(
        period: filters['period'] ?? 'month',
        serviceType: filters['serviceType'],
        status: filters['status'],
      );
    });

final analyticsRevenueProvider =
    FutureProvider.family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getRevenueData(period: period);
    });

final analyticsBookingsProvider =
    FutureProvider.family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getBookingsData(period: period);
    });

final analyticsStudentsProvider =
    FutureProvider.family<AnalyticsChartData, String>((ref, period) async {
      final service = ref.read(analyticsServiceProvider);
      return service.getStudentsData(period: period);
    });

// Provider para filtros de analytics
final analyticsFiltersProvider =
    StateNotifierProvider<AnalyticsFiltersNotifier, Map<String, String?>>((
      ref,
    ) {
      return AnalyticsFiltersNotifier();
    });

// Provider para refrescar datos
final analyticsRefreshProvider =
    StateNotifierProvider<AnalyticsRefreshNotifier, int>(
      (ref) => AnalyticsRefreshNotifier(),
    );

// Función helper para refrescar analytics
void refreshAnalytics(WidgetRef ref) {
  ref.read(analyticsRefreshProvider.notifier).refresh();
  ref.invalidate(analyticsOverviewProvider);
  ref.invalidate(analyticsRevenueProvider);
  ref.invalidate(analyticsBookingsProvider);
  ref.invalidate(analyticsStudentsProvider);
}
