import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_metric.dart';
import '../../domain/services/analytics_service.dart';

class MetricDetailWidget extends StatefulWidget {
  final AnalyticsMetric metric;

  const MetricDetailWidget({super.key, required this.metric});

  @override
  State<MetricDetailWidget> createState() => _MetricDetailWidgetState();
}

class _MetricDetailWidgetState extends State<MetricDetailWidget> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> data = {};

      switch (widget.metric.icon) {
        case 'money':
          data = await _loadRevenueDetails();
          break;
        case 'bookings':
          data = await _loadBookingsDetails();
          break;
        case 'students':
          data = await _loadStudentsDetails();
          break;
        case 'occupancy':
          data = await _loadOccupancyDetails();
          break;
        default:
          data = {'error': 'Tipo de métrica no soportado'};
      }

      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _detailData = {'error': 'Error al cargar datos: $e'};
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _loadRevenueDetails() async {
    try {
      final revenueData = await _analyticsService.getRevenueData();
      final breakdownData = await _analyticsService.getRevenueBreakdown();
      final trendData = await _analyticsService.getRevenueTrend();

      // Validate and provide safe defaults
      final breakdown =
          breakdownData != null && breakdownData['breakdown'] is List
          ? breakdownData['breakdown'] as List
          : <Map<String, dynamic>>[];

      final trend = trendData != null && trendData['trend'] is List
          ? trendData['trend'] as List
          : <Map<String, dynamic>>[];

      return {
        'type': 'revenue',
        'chartData': revenueData,
        'breakdown': breakdown,
        'totalRevenue': breakdownData?['totalRevenue'] ?? 0,
        'trend': trend,
      };
    } catch (e) {
      print('Error loading revenue details: $e');
      return {
        'type': 'revenue',
        'chartData': null,
        'breakdown': <Map<String, dynamic>>[],
        'totalRevenue': 0,
        'trend': <Map<String, dynamic>>[],
        'error': 'Error al cargar datos de ingresos: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _loadBookingsDetails() async {
    try {
      final bookingsData = await _analyticsService.getBookingsData();
      final breakdownData = await _analyticsService.getBookingsBreakdown();
      final trendData = await _analyticsService.getBookingsTrend();

      // Validate and provide safe defaults
      final breakdown =
          breakdownData != null && breakdownData['breakdown'] is List
          ? breakdownData['breakdown'] as List
          : <Map<String, dynamic>>[];

      final trend = trendData != null && trendData['trend'] is List
          ? trendData['trend'] as List
          : <Map<String, dynamic>>[];

      return {
        'type': 'bookings',
        'chartData': bookingsData,
        'breakdown': breakdown,
        'totalBookings': breakdownData?['totalBookings'] ?? 0,
        'trend': trend,
      };
    } catch (e) {
      print('Error loading bookings details: $e');
      return {
        'type': 'bookings',
        'chartData': null,
        'breakdown': <Map<String, dynamic>>[],
        'totalBookings': 0,
        'trend': <Map<String, dynamic>>[],
        'error': 'Error al cargar datos de clases: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _loadStudentsDetails() async {
    try {
      final studentsData = await _analyticsService.getStudentsData();
      final breakdownData = await _analyticsService.getStudentsBreakdown();
      final trendData = await _analyticsService.getStudentsTrend();

      // Validate and provide safe defaults
      final breakdown =
          breakdownData != null && breakdownData['breakdown'] is List
          ? breakdownData['breakdown'] as List
          : <Map<String, dynamic>>[];

      final recentStudents =
          breakdownData != null && breakdownData['recentStudents'] is List
          ? breakdownData['recentStudents'] as List
          : <Map<String, dynamic>>[];

      final trend = trendData != null && trendData['trend'] is List
          ? trendData['trend'] as List
          : <Map<String, dynamic>>[];

      return {
        'type': 'students',
        'chartData': studentsData,
        'breakdown': breakdown,
        'totalStudents': breakdownData?['totalStudents'] ?? 0,
        'recent': recentStudents,
        'trend': trend,
      };
    } catch (e) {
      print('Error loading students details: $e');
      return {
        'type': 'students',
        'chartData': null,
        'breakdown': <Map<String, dynamic>>[],
        'totalStudents': 0,
        'recent': <Map<String, dynamic>>[],
        'trend': <Map<String, dynamic>>[],
        'error': 'Error al cargar datos de estudiantes: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _loadOccupancyDetails() async {
    return {
      'type': 'occupancy',
      'breakdown': [
        {'timeSlot': '6:00 - 8:00', 'occupancy': 85, 'status': 'Alto'},
        {'timeSlot': '8:00 - 10:00', 'occupancy': 92, 'status': 'Alto'},
        {'timeSlot': '10:00 - 12:00', 'occupancy': 78, 'status': 'Medio'},
        {'timeSlot': '12:00 - 14:00', 'occupancy': 45, 'status': 'Bajo'},
        {'timeSlot': '14:00 - 16:00', 'occupancy': 65, 'status': 'Medio'},
        {'timeSlot': '16:00 - 18:00', 'occupancy': 88, 'status': 'Alto'},
        {'timeSlot': '18:00 - 20:00', 'occupancy': 95, 'status': 'Alto'},
        {'timeSlot': '20:00 - 22:00', 'occupancy': 72, 'status': 'Medio'},
      ],
      'trend': [
        {'period': 'Ene', 'value': 68},
        {'period': 'Feb', 'value': 72},
        {'period': 'Mar', 'value': 75},
        {'period': 'Abr', 'value': 78},
        {'period': 'May', 'value': 82},
        {'period': 'Jun', 'value': 85},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailData == null || _detailData!['error'] != null) {
      return _buildErrorWidget(_detailData?['error'] ?? 'Error desconocido');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendChart(),
          const Gap(24),
          _buildBreakdownSection(),
          const Gap(24),
          _buildAdditionalDetails(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const Gap(16),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: _loadDetailData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final trend = _detailData!['trend'] as List<dynamic>?;
    if (trend == null || trend.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(16),
            SizedBox(height: 200, child: _buildSimpleLineChart(trend)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLineChart(List<dynamic> data) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: SimpleLineChartPainter(data: data),
    );
  }

  Widget _buildBreakdownSection() {
    final breakdown = _detailData!['breakdown'] as List<dynamic>?;
    if (breakdown == null || breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desglose',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(16),
            ...(breakdown ?? []).map((item) => _buildBreakdownItem(item ?? {})),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.keys.contains('category')
                  ? (item['category'] ?? 'N/A')
                  : (item['status'] ?? item['timeSlot'] ?? 'N/A'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (item['percentage'] != null) ...[
            Text(
              '${item['percentage']}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const Gap(8),
            Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: item['percentage'] / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
          if (item['count'] != null) ...[
            Text(
              item['count'].toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
          if (item['amount'] != null) ...[
            Text(
              '\$${item['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
          if (item['occupancy'] != null) ...[
            Text(
              '${item['occupancy']}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getOccupancyColor(item['occupancy']),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getOccupancyColor(int occupancy) {
    if (occupancy >= 80) return Colors.green;
    if (occupancy >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAdditionalDetails() {
    if (_detailData!['type'] == 'students' && _detailData!['recent'] != null) {
      return _buildRecentStudents();
    }
    return const SizedBox.shrink();
  }

  Widget _buildRecentStudents() {
    final recent = _detailData!['recent'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiantes Recientes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(16),
            ...(recent ?? []).map(
              (student) => _buildStudentItem(student ?? {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> student) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              (student['name'] ?? 'N')[0],
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'Estudiante',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Última clase: ${student['lastClass'] ?? 'N/A'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (student['status'] ?? 'Inactivo') == 'Activo'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              student['status'] ?? 'Inactivo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: (student['status'] ?? 'Inactivo') == 'Activo'
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleLineChartPainter extends CustomPainter {
  final List<dynamic> data;

  SimpleLineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    final maxValue = data
        .map((e) => (e?['value'] as num?) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final minValue = data
        .map((e) => (e?['value'] as num?) ?? 0)
        .reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height -
          ((data[i]['value'] - minValue) / valueRange) * size.height;

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
