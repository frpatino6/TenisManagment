import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_check_service.dart';
import '../services/version_service.dart';
import 'update_required_dialog.dart';

/// Widget que envuelve el contenido y verifica actualizaciones
/// Debe usarse en las pantallas principales después de la autenticación
class UpdateCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateCheckWrapper({super.key, required this.child});

  @override
  ConsumerState<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends ConsumerState<UpdateCheckWrapper> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Inicializar VersionService si no está inicializado
    VersionService.instance.initialize();
    // Verificar actualización después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final result = await UpdateCheckService.instance.checkForUpdate();

      if (result != null && result.updateRequired && mounted) {
        await UpdateRequiredDialog.show(
          context,
          forceUpdate: result.forceUpdate,
          minVersion: result.minVersion,
        );
      }
    } catch (e) {
      // Si hay error, permitir continuar
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
