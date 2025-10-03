import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_error.dart';

/// Widget for displaying analytics errors with detailed information and retry options
class AnalyticsErrorWidget extends StatelessWidget {
  final AnalyticsError error;
  final VoidCallback? onRetry;
  final bool showDetails;

  const AnalyticsErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getErrorIcon(),
                  color: colorScheme.error,
                  size: 24,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getErrorTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      error.userMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Error details (if enabled)
          if (showDetails && error.details != null) ...[
            const Gap(16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles técnicos:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    error.details!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (error.endpoint != null) ...[
                    const Gap(8),
                    Text(
                      'Endpoint: ${error.endpoint}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (error.statusCode != null) ...[
                    Text(
                      'Código: ${error.statusCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Retry button (if error is retryable)
          if (error.isRetryable && onRetry != null) ...[
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('Reintentar (${error.retryDelay}s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],

          // Action buttons based on error type
          const Gap(12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case AnalyticsErrorType.networkError:
        return Icons.wifi_off;
      case AnalyticsErrorType.authenticationError:
        return Icons.lock;
      case AnalyticsErrorType.authorizationError:
        return Icons.block;
      case AnalyticsErrorType.dataNotFound:
        return Icons.search_off;
      case AnalyticsErrorType.dataValidationError:
        return Icons.error;
      case AnalyticsErrorType.serverError:
        return Icons.cloud_off;
      case AnalyticsErrorType.timeoutError:
        return Icons.schedule;
      case AnalyticsErrorType.unknownError:
        return Icons.help;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case AnalyticsErrorType.networkError:
        return 'Error de Conexión';
      case AnalyticsErrorType.authenticationError:
        return 'Sesión Expirada';
      case AnalyticsErrorType.authorizationError:
        return 'Sin Permisos';
      case AnalyticsErrorType.dataNotFound:
        return 'Sin Datos';
      case AnalyticsErrorType.dataValidationError:
        return 'Error de Validación';
      case AnalyticsErrorType.serverError:
        return 'Error del Servidor';
      case AnalyticsErrorType.timeoutError:
        return 'Tiempo Agotado';
      case AnalyticsErrorType.unknownError:
        return 'Error Desconocido';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (error.type) {
      case AnalyticsErrorType.authenticationError:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to login screen
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.login),
            label: const Text('Iniciar Sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        );
      case AnalyticsErrorType.dataNotFound:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to schedule creation
              Navigator.of(context).pushNamed('/professor/schedule');
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Horarios'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        );
      case AnalyticsErrorType.dataValidationError:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Clear filters and retry
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar Filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Compact error widget for smaller spaces
class AnalyticsErrorCompact extends StatelessWidget {
  final AnalyticsError error;
  final VoidCallback? onRetry;

  const AnalyticsErrorCompact({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_getErrorIcon(), color: colorScheme.error, size: 20),
          const Gap(8),
          Expanded(
            child: Text(
              error.userMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          if (error.isRetryable && onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              tooltip: 'Reintentar',
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case AnalyticsErrorType.networkError:
        return Icons.wifi_off;
      case AnalyticsErrorType.authenticationError:
        return Icons.lock;
      case AnalyticsErrorType.authorizationError:
        return Icons.block;
      case AnalyticsErrorType.dataNotFound:
        return Icons.search_off;
      case AnalyticsErrorType.dataValidationError:
        return Icons.error;
      case AnalyticsErrorType.serverError:
        return Icons.cloud_off;
      case AnalyticsErrorType.timeoutError:
        return Icons.schedule;
      case AnalyticsErrorType.unknownError:
        return Icons.help;
    }
  }
}
