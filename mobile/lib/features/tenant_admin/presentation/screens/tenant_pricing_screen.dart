import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantPricingScreen extends ConsumerStatefulWidget {
  const TenantPricingScreen({super.key});

  @override
  ConsumerState<TenantPricingScreen> createState() =>
      _TenantPricingScreenState();
}

class _TenantPricingScreenState extends ConsumerState<TenantPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _individualClassController;
  late TextEditingController _groupClassController;
  late TextEditingController _courtRentalController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _individualClassController = TextEditingController();
    _groupClassController = TextEditingController();
    _courtRentalController = TextEditingController();
  }

  @override
  void dispose() {
    _individualClassController.dispose();
    _groupClassController.dispose();
    _courtRentalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantInfo = ref.watch(tenantInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Precios Base'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: tenantInfo.when(
        data: (tenant) {
          final basePricing = tenant.config?.basePricing;
          _individualClassController.text =
              basePricing?.individualClass.toString() ?? '0';
          _groupClassController.text =
              basePricing?.groupClass.toString() ?? '0';
          _courtRentalController.text =
              basePricing?.courtRental.toString() ?? '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precios Base del Centro',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Estos precios se usarán como valores por defecto. Los profesores pueden tener precios personalizados.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(24),
                  TextFormField(
                    controller: _individualClassController,
                    decoration: const InputDecoration(
                      labelText: 'Clase Individual',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El precio es requerido';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Ingrese un precio válido';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _groupClassController,
                    decoration: const InputDecoration(
                      labelText: 'Clase Grupal',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El precio es requerido';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Ingrese un precio válido';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _courtRentalController,
                    decoration: const InputDecoration(
                      labelText: 'Alquiler de Cancha',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El precio es requerido';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Ingrese un precio válido';
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
          'basePricing': {
            'individualClass': double.parse(_individualClassController.text),
            'groupClass': double.parse(_groupClassController.text),
            'courtRental': double.parse(_courtRentalController.text),
          },
        },
      };

      await service.updateTenantInfo(updates);

      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precios actualizados exitosamente'),
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
