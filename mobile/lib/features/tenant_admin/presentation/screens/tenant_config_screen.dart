import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantConfigScreen extends ConsumerStatefulWidget {
  const TenantConfigScreen({super.key});

  @override
  ConsumerState<TenantConfigScreen> createState() => _TenantConfigScreenState();
}

class _TenantConfigScreenState extends ConsumerState<TenantConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _domainController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _domainController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantInfo = ref.watch(tenantInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Centro'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: tenantInfo.when(
        data: (tenant) {
          _nameController.text = tenant.name;
          _slugController.text = tenant.slug;
          _domainController.text = tenant.domain ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Básica',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Centro',
                      hintText: 'Ej: Club de Tenis Central',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      labelText: 'Slug (URL-friendly)',
                      hintText: 'Ej: club-tenis-central',
                      border: OutlineInputBorder(),
                      helperText:
                          'Usado en URLs, solo letras, números y guiones',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El slug es requerido';
                      }
                      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                        return 'Solo letras minúsculas, números y guiones';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _domainController,
                    decoration: const InputDecoration(
                      labelText: 'Dominio (Opcional)',
                      hintText: 'Ej: clubtenis.com',
                      border: OutlineInputBorder(),
                    ),
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
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tenant-branding'),
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('Branding'),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tenant-pricing'),
                          icon: const Icon(Icons.attach_money_outlined),
                          label: const Text('Precios'),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tenant-operating-hours'),
                      icon: const Icon(Icons.access_time_outlined),
                      label: const Text('Horarios de Operación'),
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
      await service.updateTenantInfo({
        'name': _nameController.text.trim(),
        'slug': _slugController.text.trim(),
        if (_domainController.text.trim().isNotEmpty)
          'domain': _domainController.text.trim(),
      });

      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración actualizada exitosamente'),
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
