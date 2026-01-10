import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../providers/tenant_admin_provider.dart';

class EditProfessorSheet extends ConsumerStatefulWidget {
  final TenantProfessorModel professor;

  const EditProfessorSheet({super.key, required this.professor});

  @override
  ConsumerState<EditProfessorSheet> createState() => _EditProfessorSheetState();
}

class _EditProfessorSheetState extends ConsumerState<EditProfessorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _specialtiesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.professor.name);
    _phoneController = TextEditingController(
      text: widget.professor.phone ?? '',
    );
    _hourlyRateController = TextEditingController(
      text: widget.professor.hourlyRate.toString(),
    );
    _specialtiesController = TextEditingController(
      text: widget.professor.specialties.join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final specialties = _specialtiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final service = ref.read(tenantAdminServiceProvider);
      await service.updateProfessor(
        professorId: widget.professor.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
        specialties: specialties,
      );

      // Refresh the professors list
      ref.invalidate(tenantProfessorsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, viewInsets.bottom + 24),
      constraints: const BoxConstraints(maxHeight: 600), // Limit height
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Editar Perfil',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Gap(16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const Gap(16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const Gap(16),

              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Tarifa por Hora',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Inválido';
                  return null;
                },
              ),
              const Gap(16),

              TextFormField(
                controller: _specialtiesController,
                decoration: const InputDecoration(
                  labelText: 'Especialidades (separadas por coma)',
                  prefixIcon: Icon(Icons.star_outline),
                  hintText: 'Ej: Tenis, Pádel, Infantil',
                ),
              ),

              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
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
      ),
    );
  }
}
