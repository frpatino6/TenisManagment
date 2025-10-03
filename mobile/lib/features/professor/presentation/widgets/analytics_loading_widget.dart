import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Enhanced loading widget for analytics with specific indicators and better UX
class AnalyticsLoadingWidget extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final LoadingType type;
  final double? progress;
  final List<String>? steps;
  final int? currentStep;

  const AnalyticsLoadingWidget({
    super.key,
    this.title,
    this.subtitle,
    this.type = LoadingType.overview,
    this.progress,
    this.steps,
    this.currentStep,
  });

  @override
  State<AnalyticsLoadingWidget> createState() => _AnalyticsLoadingWidgetState();
}

class _AnalyticsLoadingWidgetState extends State<AnalyticsLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress ?? 1.0)
        .animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _startAnimations();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingIndicator(theme, colorScheme),
          const Gap(24),
          _buildLoadingText(theme, colorScheme),
          if (widget.steps != null && widget.steps!.isNotEmpty) ...[
            const Gap(24),
            _buildStepsIndicator(theme, colorScheme),
          ],
          if (widget.progress != null) ...[
            const Gap(24),
            _buildProgressIndicator(theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, ColorScheme colorScheme) {
    switch (widget.type) {
      case LoadingType.overview:
        return _buildOverviewLoading(theme, colorScheme);
      case LoadingType.metrics:
        return _buildMetricsLoading(theme, colorScheme);
      case LoadingType.charts:
        return _buildChartsLoading(theme, colorScheme);
      case LoadingType.details:
        return _buildDetailsLoading(theme, colorScheme);
    }
  }

  Widget _buildOverviewLoading(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(Icons.analytics, size: 40, color: colorScheme.primary),
          ),
        );
      },
    );
  }

  Widget _buildMetricsLoading(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_pulseController.value + delay) % 1.0;
            final scale = 0.8 + (0.4 * (1 - (animationValue - 0.5).abs() * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildChartsLoading(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: Icon(Icons.bar_chart, size: 30, color: colorScheme.primary),
          ),
        );
      },
    );
  }

  Widget _buildDetailsLoading(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.insights, size: 35, color: colorScheme.primary),
          ),
        );
      },
    );
  }

  Widget _buildLoadingText(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          widget.title ?? _getDefaultTitle(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.subtitle != null) ...[
          const Gap(8),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStepsIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Procesando datos...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(12),
        ...widget.steps!.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == (widget.currentStep ?? 0);
          final isCompleted = index < (widget.currentStep ?? 0);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? colorScheme.primary
                        : isActive
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: colorScheme.onPrimary,
                        )
                      : isActive
                      ? AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive || isCompleted
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Progreso: ${((widget.progress ?? 0) * 100).toInt()}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Gap(8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 6,
            );
          },
        ),
      ],
    );
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case LoadingType.overview:
        return 'Cargando Analytics';
      case LoadingType.metrics:
        return 'Calculando Métricas';
      case LoadingType.charts:
        return 'Generando Gráficos';
      case LoadingType.details:
        return 'Obteniendo Detalles';
    }
  }
}

enum LoadingType { overview, metrics, charts, details }

/// Compact loading widget for smaller spaces
class AnalyticsLoadingCompact extends StatefulWidget {
  final String? message;
  final LoadingType type;

  const AnalyticsLoadingCompact({
    super.key,
    this.message,
    this.type = LoadingType.overview,
  });

  @override
  State<AnalyticsLoadingCompact> createState() =>
      _AnalyticsLoadingCompactState();
}

class _AnalyticsLoadingCompactState extends State<AnalyticsLoadingCompact>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_animation.value * 0.5),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const Gap(12),
          Text(
            widget.message ?? 'Cargando...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for analytics cards
class AnalyticsSkeletonLoading extends StatefulWidget {
  final int itemCount;
  final SkeletonType type;

  const AnalyticsSkeletonLoading({
    super.key,
    this.itemCount = 4,
    this.type = SkeletonType.metric,
  });

  @override
  State<AnalyticsSkeletonLoading> createState() =>
      _AnalyticsSkeletonLoadingState();
}

class _AnalyticsSkeletonLoadingState extends State<AnalyticsSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_animation.value * 0.4),
          child: _buildSkeletonContent(theme, colorScheme),
        );
      },
    );
  }

  Widget _buildSkeletonContent(ThemeData theme, ColorScheme colorScheme) {
    switch (widget.type) {
      case SkeletonType.metric:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => _buildMetricSkeleton(colorScheme),
        );
      case SkeletonType.chart:
        return Column(
          children: List.generate(
            widget.itemCount,
            (index) => _buildChartSkeleton(colorScheme),
          ),
        );
    }
  }

  Widget _buildMetricSkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Gap(12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(8),
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

enum SkeletonType { metric, chart }
