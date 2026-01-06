import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../providers/tenant_admin_provider.dart';

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
  final _individualPriceController = TextEditingController();
  final _groupPriceController = TextEditingController();
  final _courtRentalController = TextEditingController();

  bool _isLoading = false;
  bool _showPricing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _individualPriceController.dispose();
    _groupPriceController.dispose();
    _courtRentalController.dispose();
    super.dispose();
  }

  Future<void> _inviteProfessor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);

      Map<String, dynamic>? pricing;
      if (_showPricing) {
        pricing = {};
        if (_individualPriceController.text.isNotEmpty) {
          pricing['individualClass'] = double.parse(
            _individualPriceController.text,
          );
        }
        if (_groupPriceController.text.isNotEmpty) {
          pricing['groupClass'] = double.parse(_groupPriceController.text);
        }
        if (_courtRentalController.text.isNotEmpty) {
          pricing['courtRental'] = double.parse(_courtRentalController.text);
        }
        if (pricing.isEmpty) {
          pricing = null;
        }
      }

      await service.inviteProfessor(
        email: _emailController.text.trim(),
        pricing: pricing,
      );

      // Refresh professors list
      ref.invalidate(tenantProfessorsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profesor invitado exitosamente'),
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
            content: Text('Error al invitar profesor: ${e.toString()}'),
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
          'Invitar Profesor',
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
            onPressed: _isLoading ? null : _inviteProfessor,
            child: Text(
              'Invitar',
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
              Card(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          'Si el profesor no está registrado, se creará automáticamente y deberá completar su registro para acceder al centro.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              _buildTextField(
                controller: _emailController,
                label: 'Email del Profesor',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El email es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const Gap(24),
              Card(
                child: ExpansionTile(
                  title: Text(
                    'Precios Personalizados (Opcional)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _showPricing
                        ? 'Los precios personalizados se aplicarán solo a este profesor'
                        : 'Si no se especifican, se usarán los precios base del centro',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  leading: Icon(Icons.attach_money, color: colorScheme.primary),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showPricing = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPriceField(
                            controller: _individualPriceController,
                            label: 'Clase Individual',
                            icon: Icons.person,
                          ),
                          const Gap(16),
                          _buildPriceField(
                            controller: _groupPriceController,
                            label: 'Clase Grupal',
                            icon: Icons.people,
                          ),
                          const Gap(16),
                          _buildPriceField(
                            controller: _courtRentalController,
                            label: 'Alquiler de Cancha',
                            icon: Icons.sports_tennis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _inviteProfessor,
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
                          'Enviar Invitación',
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
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
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
        if (value != null && value.isNotEmpty) {
          final price = double.tryParse(value);
          if (price == null || price < 0) {
            return 'Precio inválido';
          }
        }
        return null;
      },
    );
  }
}
