import 'package:flutter/material.dart';

/// Reusable loading widget with optional message
///
/// Use this widget to show loading states consistently across the app
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const LoadingWidget({super.key, this.message, this.size, this.color});

  /// Full screen loading widget with message
  const LoadingWidget.fullScreen({
    super.key,
    required this.message,
    this.size,
    this.color,
  });

  /// Small inline loading indicator
  const LoadingWidget.small({
    super.key,
    this.message,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final indicator = SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: CircularProgressIndicator(
        strokeWidth: size != null && size! < 30 ? 2.5 : 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? colorScheme.primary),
      ),
    );

    if (message != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            indicator,
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(child: indicator);
  }
}
