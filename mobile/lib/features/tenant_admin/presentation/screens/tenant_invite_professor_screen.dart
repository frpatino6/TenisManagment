import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantInviteProfessorScreen extends ConsumerStatefulWidget {
  const TenantInviteProfessorScreen({super.key});

  @override
  ConsumerState<TenantInviteProfessorScreen> createState() =>
      _TenantInviteProfessorScreenState();
}

class _TenantInviteProfessorScreenState
    extends ConsumerState<TenantInviteProfessorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _individualClassController = TextEditingController();
  final _groupClassController = TextEditingController();
  final _courtRentalController = TextEditingController();
  bool _useCustomPricing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _individualClassController.dispose();
    _groupClassController.dispose();
    _courtRentalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar Profesor'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información del Profesor',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Gap(8),
              Text(
                'El profesor recibirá una invitación por email para unirse al centro.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email del Profesor',
                  hintText: 'profesor@ejemplo.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El email es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
              ),
              const Gap(24),
              CheckboxListTile(
                title: const Text('Usar precios personalizados'),
                subtitle: const Text(
                  'Si no se marca, se usarán los precios base del centro',
                ),
                value: _useCustomPricing,
                onChanged: (value) {
                  setState(() {
                    _useCustomPricing = value ?? false;
                  });
                },
              ),
              if (_useCustomPricing) ...[
                const Gap(16),
                Text(
                  'Precios Personalizados',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Gap(16),
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
                    if (_useCustomPricing &&
                        (value == null || value.isEmpty)) {
                      return 'El precio es requerido';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
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
                    if (_useCustomPricing &&
                        (value == null || value.isEmpty)) {
                      return 'El precio es requerido';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
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
                    if (_useCustomPricing &&
                        (value == null || value.isEmpty)) {
                      return 'El precio es requerido';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Ingrese un precio válido';
                    }
                    return null;
                  },
                ),
              ],
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleInvite,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar Invitación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      ProfessorPricing? pricing;

      if (_useCustomPricing) {
        pricing = ProfessorPricing(
          individualClass: double.parse(_individualClassController.text),
          groupClass: double.parse(_groupClassController.text),
          courtRental: double.parse(_courtRentalController.text),
        );
      }

      final request = InviteProfessorRequest(
        email: _emailController.text.trim(),
        pricing: pricing,
      );

      await service.inviteProfessor(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitación enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar invitación: $e'),
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

