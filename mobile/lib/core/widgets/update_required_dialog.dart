import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateRequiredDialog extends StatelessWidget {
  final bool forceUpdate;
  final String minVersion;

  const UpdateRequiredDialog({
    super.key,
    required this.forceUpdate,
    required this.minVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate, // No permitir cerrar si es forzado
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Actualización Requerida'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hay una nueva versión disponible de la aplicación.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Versión mínima requerida: $minVersion',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor, actualiza la aplicación para continuar usando el servicio.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Más tarde'),
            ),
          ElevatedButton(
            onPressed: () {
              // Cerrar la aplicación
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de actualización requerida
  static Future<bool?> show(BuildContext context, {
    required bool forceUpdate,
    required String minVersion,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !forceUpdate, // No permitir cerrar si es forzado
      builder: (context) => UpdateRequiredDialog(
        forceUpdate: forceUpdate,
        minVersion: minVersion,
      ),
    );
  }
}

