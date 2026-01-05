import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

/// Reusable empty state widget
///
/// Use this widget to show empty states (no data) consistently across the app
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.action,
  });

  /// Empty state for lists
  const EmptyStateWidget.list({
    super.key,
    this.title = AppStrings.emptyListTitle,
    this.message = AppStrings.emptyListMessage,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  /// Empty state for search results
  const EmptyStateWidget.search({
    super.key,
    this.title = AppStrings.emptySearchTitle,
    this.message = AppStrings.emptySearchMessage,
    this.icon = Icons.search_off,
    this.action,
  });

  /// Empty state for schedules
  const EmptyStateWidget.schedule({
    super.key,
    this.title = AppStrings.emptyScheduleTitle,
    this.message = AppStrings.emptyScheduleMessage,
    this.icon = Icons.event_busy,
    this.action,
  });

  /// Empty state for bookings
  const EmptyStateWidget.booking({
    super.key,
    this.title = AppStrings.emptyBookingTitle,
    this.message = AppStrings.emptyBookingMessage,
    this.icon = Icons.calendar_today_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null && message != null) const SizedBox(height: 8),
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
