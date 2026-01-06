import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_court_model.dart';

class TenantEditCourtScreen extends ConsumerStatefulWidget {
  final String courtId;

  const TenantEditCourtScreen({super.key, required this.courtId});

  @override
  ConsumerState<TenantEditCourtScreen> createState() =>
      _TenantEditCourtScreenState();
}

class _TenantEditCourtScreenState extends ConsumerState<TenantEditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featuresController = TextEditingController();

  String? _selectedType;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _loadCourtData(TenantCourtModel court) {
    _nameController.text = court.name;
    _selectedType = court.type;
    _priceController.text = court.price.toStringAsFixed(0);
    _descriptionController.text = court.description ?? '';
    _featuresController.text = court.features.join(', ');
    _hasChanges = false;
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveCourt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);

      // Parse features from comma-separated string
      final featuresList = _featuresController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      await service.updateCourt(
        courtId: widget.courtId,
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
            content: Text('Cancha actualizada exitosamente'),
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
            content: Text('Error al actualizar cancha: ${e.toString()}'),
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

    final courtsAsync = ref.watch(tenantCourtsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Editar Cancha',
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
            onPressed: _isLoading || !_hasChanges ? null : _saveCourt,
            child: Text(
              'Guardar',
              style: GoogleFonts.inter(
                color: _hasChanges
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: courtsAsync.when(
        data: (courts) {
          final court = courts.firstWhere(
            (c) => c.id == widget.courtId,
            orElse: () => throw Exception('Cancha no encontrada'),
          );

          if (_nameController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadCourtData(court);
            });
          }

          return _buildForm(context);
        },
        loading: () => const LoadingWidget(message: 'Cargando cancha...'),
        error: (error, stackTrace) {
          if (error is AuthException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/login');
              }
            });
            return const SizedBox.shrink();
          }
          return AppErrorWidget.fromError(
            error,
            onRetry: () => ref.invalidate(tenantCourtsProvider),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      onChanged: _markAsChanged,
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
              onChanged: (_) => _markAsChanged(),
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
              onChanged: (_) => _markAsChanged(),
            ),
            const Gap(16),
            _buildTextField(
              controller: _featuresController,
              label: 'Características (separadas por comas, opcional)',
              icon: Icons.list,
              hintText: 'Ej: techada, iluminación, vestuarios',
              onChanged: (_) => _markAsChanged(),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_hasChanges ? null : _saveCourt,
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
                        'Guardar Cambios',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
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

    if (_selectedType == null) {
      return const SizedBox.shrink();
    }

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
            _markAsChanged();
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
      onChanged: (_) => _markAsChanged(),
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
