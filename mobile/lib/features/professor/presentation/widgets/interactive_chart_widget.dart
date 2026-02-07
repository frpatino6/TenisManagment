import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Interactive chart widget with tooltips and better visualization
class InteractiveChartWidget extends StatefulWidget {
  final String title;
  final List<ChartDataPoint> data;
  final String xAxisLabel;
  final String yAxisLabel;
  final String? description;
  final ChartType type;
  final double height;

  const InteractiveChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.xAxisLabel,
    required this.yAxisLabel,
    this.description,
    this.type = ChartType.line,
    this.height = 300,
  });

  @override
  State<InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget> {
  int? _touchedIndex;
  bool _showTooltip = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, colorScheme),
            const Gap(16),

            SizedBox(
              height: widget.height,
              child: RepaintBoundary(child: _buildChart(theme, colorScheme)),
            ),

            if (widget.data.isNotEmpty) ...[
              const Gap(16),
              _buildLegend(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (widget.description != null) ...[
                const Gap(4),
                Text(
                  widget.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),

        Row(
          children: [
            IconButton(
              onPressed: _showTooltip ? _hideTooltip : _showTooltipInfo,
              icon: Icon(
                _showTooltip ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              tooltip: _showTooltip ? 'Ocultar tooltips' : 'Mostrar tooltips',
            ),
            IconButton(
              onPressed: _resetView,
              icon: const Icon(Icons.zoom_out_map, size: 20),
              tooltip: 'Restablecer vista',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(ThemeData theme, ColorScheme colorScheme) {
    if (widget.data.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    switch (widget.type) {
      case ChartType.line:
        return _buildLineChart(theme, colorScheme);
      case ChartType.bar:
        return _buildBarChart(theme, colorScheme);
      case ChartType.pie:
        return _buildPieChart(theme, colorScheme);
    }
  }

  Widget _buildLineChart(ThemeData theme, ColorScheme colorScheme) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: LineChartPainter(
        data: widget.data,
        color: colorScheme.primary,
        touchedIndex: _touchedIndex,
        showTooltip: _showTooltip,
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme, ColorScheme colorScheme) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: BarChartPainter(
        data: widget.data,
        color: colorScheme.primary,
        touchedIndex: _touchedIndex,
        showTooltip: _showTooltip,
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme, ColorScheme colorScheme) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: PieChartPainter(
        data: widget.data,
        touchedIndex: _touchedIndex,
        showTooltip: _showTooltip,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const Gap(16),
          Text(
            'No hay datos para mostrar',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Gap(8),
          Text(
            'Los gráficos aparecerán cuando tengas datos disponibles',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, ColorScheme colorScheme) {
    if (widget.type == ChartType.pie) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: widget.data.asMap().entries.map((entry) {
          final index = entry.key;
          final dataPoint = entry.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForIndex(index),
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(8),
              Text(
                dataPoint.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            'Toca los puntos para ver detalles',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  void _showTooltipInfo() {
    setState(() {
      _showTooltip = true;
    });
  }

  void _hideTooltip() {
    setState(() {
      _showTooltip = false;
      _touchedIndex = null;
    });
  }

  void _resetView() {
    setState(() {
      _touchedIndex = null;
      _showTooltip = false;
    });
  }
}

enum ChartType { line, bar, pie }

class ChartDataPoint {
  final String label;
  final double value;
  final String? color;
  final DateTime? date;
  final String? serviceType;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.date,
    this.serviceType,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      value: (json['value'] as num? ?? 0).toDouble(),
      color: json['color'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      serviceType: json['serviceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color,
      'date': date?.toIso8601String(),
      'serviceType': serviceType,
    };
  }
}

/// Custom painter for line charts
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color color;
  final int? touchedIndex;
  final bool showTooltip;

  LineChartPainter({
    required this.data,
    required this.color,
    this.touchedIndex,
    this.showTooltip = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    final padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y =
          padding +
          chartHeight -
          ((data[i].value - minValue) / valueRange) * chartHeight;

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final areaPath = Path.from(path);
    areaPath.lineTo(padding + chartWidth, padding + chartHeight);
    areaPath.lineTo(padding, padding + chartHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, paint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final radius = (touchedIndex == i && showTooltip) ? 8.0 : 5.0;

      canvas.drawCircle(point, radius, pointPaint);

      canvas.drawCircle(point, radius - 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for bar charts
class BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color color;
  final int? touchedIndex;
  final bool showTooltip;

  BarChartPainter({
    required this.data,
    required this.color,
    this.touchedIndex,
    this.showTooltip = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final barWidth = chartWidth / data.length * 0.6;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i].value / maxValue) * chartHeight;
      final x =
          padding +
          (i * chartWidth / data.length) +
          (chartWidth / data.length - barWidth) / 2;
      final y = padding + chartHeight - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final paint = Paint()
        ..color = (touchedIndex == i && showTooltip)
            ? color.withValues(alpha: 0.8)
            : color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for pie charts
class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final int? touchedIndex;
  final bool showTooltip;

  PieChartPainter({
    required this.data,
    this.touchedIndex,
    this.showTooltip = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.map((e) => e.value).reduce((a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 - 20;

    double startAngle = -3.14159 / 2; // Start from top

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = _getColorForIndex(i)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
