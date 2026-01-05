import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantBrandingScreen extends ConsumerStatefulWidget {
  const TenantBrandingScreen({super.key});

  @override
  ConsumerState<TenantBrandingScreen> createState() =>
      _TenantBrandingScreenState();
}

class _TenantBrandingScreenState extends ConsumerState<TenantBrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _logoController;
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logoController = TextEditingController();
    _primaryColorController = TextEditingController();
    _secondaryColorController = TextEditingController();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantInfo = ref.watch(tenantInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branding'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: tenantInfo.when(
        data: (tenant) {
          final config = tenant.config;
          _logoController.text = config?.logo ?? '';
          _primaryColorController.text = config?.primaryColor ?? '';
          _secondaryColorController.text = config?.secondaryColor ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalización Visual',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(24),
                  TextFormField(
                    controller: _logoController,
                    decoration: const InputDecoration(
                      labelText: 'URL del Logo',
                      hintText: 'https://ejemplo.com/logo.png',
                      border: OutlineInputBorder(),
                      helperText: 'URL de la imagen del logo',
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _primaryColorController,
                    decoration: const InputDecoration(
                      labelText: 'Color Primario',
                      hintText: '#2196F3',
                      border: OutlineInputBorder(),
                      helperText: 'Color en formato hexadecimal (ej: #2196F3)',
                      prefixText: '#',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
                          return 'Formato inválido (ej: 2196F3)';
                        }
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _secondaryColorController,
                    decoration: const InputDecoration(
                      labelText: 'Color Secundario',
                      hintText: '#FF9800',
                      border: OutlineInputBorder(),
                      helperText: 'Color en formato hexadecimal (ej: #FF9800)',
                      prefixText: '#',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
                          return 'Formato inválido (ej: FF9800)';
                        }
                      }
                      return null;
                    },
                  ),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(tenantInfoProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      final updates = <String, dynamic>{
        'config': {
          'logo': _logoController.text.trim().isEmpty
              ? null
              : _logoController.text.trim(),
          'primaryColor': _primaryColorController.text.trim().isEmpty
              ? null
              : '#${_primaryColorController.text.trim()}',
          'secondaryColor': _secondaryColorController.text.trim().isEmpty
              ? null
              : '#${_secondaryColorController.text.trim()}',
        },
      };

      await service.updateTenantInfo(updates);

      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branding actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
