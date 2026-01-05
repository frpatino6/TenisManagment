import 'package:flutter/material.dart';
import '../exceptions/app_exception.dart';
import '../constants/app_strings.dart';

/// Reusable error widget for displaying errors consistently
///
/// Use this widget to show error states across the app
class AppErrorWidget extends StatelessWidget {
  final Object? error;
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.icon,
  });

  /// Creates an error widget from an AppException
  factory AppErrorWidget.fromException(
    AppException exception, {
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      error: exception,
      message: exception.message,
      onRetry: onRetry,
    );
  }

  /// Creates an error widget from a generic error
  factory AppErrorWidget.fromError(
    Object error, {
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      error: error,
      message: message ?? error.toString(),
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String displayMessage;
    if (message != null) {
      displayMessage = message!;
    } else if (error is AppException) {
      displayMessage = (error as AppException).message;
    } else {
      displayMessage = AppStrings.errorGeneric;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
