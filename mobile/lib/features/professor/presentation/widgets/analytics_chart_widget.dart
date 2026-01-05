import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_chart_data.dart';

class AnalyticsChartWidget extends StatelessWidget {
  final AnalyticsChartData chartData;
  final double height;

  const AnalyticsChartWidget({
    super.key,
    required this.chartData,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  AnalyticsChartWidget._getChartIcon(chartData.type),
                  color: colorScheme.primary,
                  size: 20,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    chartData.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (chartData.description != null) ...[
              const Gap(4),
              Text(
                chartData.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Gap(16),
            SizedBox(
              height: height,
              child: RepaintBoundary(child: _buildChart(context)),
            ),
            if (chartData.xAxisLabel != null ||
                chartData.yAxisLabel != null) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (chartData.xAxisLabel != null)
                    Text(
                      chartData.xAxisLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (chartData.yAxisLabel != null)
                    Text(
                      chartData.yAxisLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    switch (chartData.type) {
      case ChartType.line:
        return _buildLineChart(context);
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.pie:
        return _buildPieChart(context);
      case ChartType.area:
        return _buildAreaChart(context);
    }
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (chartData.data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }

    return CustomPaint(
      painter: LineChartPainter(
        data: chartData.data,
        color: colorScheme.primary,
      ),
      child: Container(),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (chartData.data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }

    final maxValue = chartData.data
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chartData.data.map((point) {
        final height = (point.value / maxValue) * (this.height - 40);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Gap(4),
            SizedBox(
              width: 50,
              child: Text(
                point.label,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (chartData.data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomPaint(
            painter: PieChartPainter(
              data: chartData.data,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
            child: Container(),
          ),
        ),
        const Gap(16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chartData.data.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final colors = [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        point.label,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (chartData.data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }

    return CustomPaint(
      painter: AreaChartPainter(
        data: chartData.data,
        color: colorScheme.primary,
      ),
      child: Container(),
    );
  }

  Widget _buildEmptyChart(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const Gap(8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getChartIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.area:
        return Icons.area_chart;
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final validData = data
        .where((e) => e.value.isFinite && !e.value.isNaN)
        .toList();
    if (validData.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = validData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    final stepX = validData.length > 1
        ? size.width / (validData.length - 1)
        : 0.0;

    for (int i = 0; i < validData.length; i++) {
      final x = validData.length > 1 ? i * stepX : size.width / 2;
      final y = maxValue > 0
          ? size.height - (validData[i].value / maxValue) * size.height
          : size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < validData.length; i++) {
      final x = validData.length > 1 ? i * stepX : size.width / 2;
      final y = maxValue > 0
          ? size.height - (validData[i].value / maxValue) * size.height
          : size.height / 2;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<Color> colors;

  PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final validData = data
        .where((e) => e.value.isFinite && !e.value.isNaN && e.value > 0)
        .toList();
    if (validData.isEmpty) return;

    final total = validData.map((e) => e.value).reduce((a, b) => a + b);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 - 20;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < validData.length; i++) {
      final sweepAngle = (validData[i].value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AreaChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color color;

  AreaChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final stepX = size.width / (data.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i].value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
