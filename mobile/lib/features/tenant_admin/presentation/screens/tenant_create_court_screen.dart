import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../providers/tenant_admin_provider.dart';

class TenantCreateCourtScreen extends ConsumerStatefulWidget {
  const TenantCreateCourtScreen({super.key});

  @override
  ConsumerState<TenantCreateCourtScreen> createState() =>
      _TenantCreateCourtScreenState();
}

class _TenantCreateCourtScreenState
    extends ConsumerState<TenantCreateCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featuresController = TextEditingController();

  String _selectedType = 'tennis';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _saveCourt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(tenantAdminRepositoryProvider);

      // Parse features from comma-separated string
      final featuresList = _featuresController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      await repository.createCourt(
        name: _nameController.text.trim(),
        type: _selectedType,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        features: featuresList.isEmpty ? null : featuresList,
      );

      // Refresh courts list
      ref.invalidate(tenantCourtsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancha creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear cancha: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Nueva Cancha',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCourt,
            child: Text(
              'Guardar',
              style: GoogleFonts.inter(
                color: _isLoading
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nombre de la Cancha',
                icon: Icons.sports_tennis,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const Gap(16),
              _buildTypeDropdown(),
              const Gap(16),
              _buildPriceField(),
              const Gap(16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripción (opcional)',
                icon: Icons.description,
                maxLines: 3,
              ),
              const Gap(16),
              _buildTextField(
                controller: _featuresController,
                label: 'Características (separadas por comas, opcional)',
                icon: Icons.list,
                hintText: 'Ej: techada, iluminación, vestuarios',
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCourt,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Crear Cancha',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: InputDecoration(
        labelText: 'Tipo de Cancha',
        prefixIcon: Icon(Icons.category, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      items: const [
        DropdownMenuItem(value: 'tennis', child: Text('Tenis')),
        DropdownMenuItem(value: 'padel', child: Text('Padel')),
        DropdownMenuItem(value: 'multi', child: Text('Multi-deporte')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona un tipo';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Precio por hora',
        prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
        prefixText: '\$ ',
        suffixText: 'COP',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El precio es requerido';
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Precio inválido';
        }
        return null;
      },
    );
  }
}
