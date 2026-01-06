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
import '../../domain/models/tenant_config_model.dart';

class TenantConfigScreen extends ConsumerStatefulWidget {
  const TenantConfigScreen({super.key});

  @override
  ConsumerState<TenantConfigScreen> createState() => _TenantConfigScreenState();
}

class _TenantConfigScreenState extends ConsumerState<TenantConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _domainController = TextEditingController();
  final _individualPriceController = TextEditingController();
  final _groupPriceController = TextEditingController();
  final _courtRentalController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _primaryColorController = TextEditingController();
  final _secondaryColorController = TextEditingController();
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  List<int> _selectedDays = [0, 1, 2, 3, 4, 5, 6]; // All days by default
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isSavingOperatingHours = false;

  // Accordion expansion states
  bool _isBasicInfoExpanded = true;
  bool _isPricingExpanded = false;
  bool _isOperatingHoursExpanded = false;
  bool _isBrandingExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    _individualPriceController.dispose();
    _groupPriceController.dispose();
    _courtRentalController.dispose();
    _logoUrlController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  void _loadTenantInfo(TenantConfigModel tenant) {
    _nameController.text = tenant.name;
    _slugController.text = tenant.slug;
    _domainController.text = tenant.domain ?? '';

    // Load pricing
    final basePricing = tenant.config?.basePricing;
    if (basePricing != null) {
      _individualPriceController.text = basePricing.individualClass
          .toStringAsFixed(0);
      _groupPriceController.text = basePricing.groupClass.toStringAsFixed(0);
      _courtRentalController.text = basePricing.courtRental.toStringAsFixed(0);
    } else {
      // Default values if pricing is not configured
      _individualPriceController.text = '50000';
      _groupPriceController.text = '35000';
      _courtRentalController.text = '25000';
    }

    // Load operating hours
    final operatingHours = tenant.config?.operatingHours;
    if (operatingHours != null) {
      _openTime = _parseTimeString(operatingHours.open);
      _closeTime = _parseTimeString(operatingHours.close);
      _selectedDays = List<int>.from(operatingHours.daysOfWeek);
    } else {
      // Default values
      _openTime = const TimeOfDay(hour: 6, minute: 0);
      _closeTime = const TimeOfDay(hour: 22, minute: 0);
      _selectedDays = [0, 1, 2, 3, 4, 5, 6];
    }

    // Load branding
    final config = tenant.config;
    _logoUrlController.text = config?.logo ?? '';
    _primaryColorController.text = config?.primaryColor ?? '';
    _secondaryColorController.text = config?.secondaryColor ?? '';

    _hasChanges = false;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 6;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 6, minute: 0);
  }

  String _formatTimeString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantInfoAsync = ref.watch(tenantInfoProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Configuración del Centro',
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
            onPressed: _isLoading || !_hasChanges ? null : _saveConfiguration,
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
      body: tenantInfoAsync.when(
        data: (tenant) {
          if (_nameController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadTenantInfo(tenant);
            });
          }
          return _buildForm(context, tenant);
        },
        loading: () =>
            const LoadingWidget(message: 'Cargando configuración...'),
        error: (error, stackTrace) {
          // Check if it's an authentication error
          if (error is AuthException) {
            // Redirect to login on auth errors
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/login');
              }
            });
            return const SizedBox.shrink();
          }
          return AppErrorWidget.fromError(
            error,
            onRetry: () => ref.invalidate(tenantInfoProvider),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, TenantConfigModel tenant) {
    return Form(
      key: _formKey,
      onChanged: _markAsChanged,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccordionSection(
              context,
              title: 'Información Básica',
              icon: Icons.info_outline,
              isExpanded: _isBasicInfoExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isBasicInfoExpanded = value;
                });
              },
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre del Centro',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildTextField(
                  controller: _slugController,
                  label: 'Slug (identificador único)',
                  icon: Icons.tag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El slug es requerido';
                    }
                    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                      return 'El slug solo puede contener letras minúsculas, números y guiones';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildTextField(
                  controller: _domainController,
                  label: 'Dominio (opcional)',
                  icon: Icons.language,
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildInfoCard(
                  context,
                  'Información',
                  'El slug se usa como identificador único en las URLs. '
                      'Solo puede contener letras minúsculas, números y guiones.',
                  Icons.help_outline,
                ),
              ],
            ),
            const Gap(16),
            _buildAccordionSection(
              context,
              title: 'Precios Base',
              icon: Icons.attach_money,
              isExpanded: _isPricingExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isPricingExpanded = value;
                });
              },
              children: [
                _buildPriceField(
                  controller: _individualPriceController,
                  label: 'Clase Individual',
                  icon: Icons.person,
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildPriceField(
                  controller: _groupPriceController,
                  label: 'Clase Grupal',
                  icon: Icons.people,
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildPriceField(
                  controller: _courtRentalController,
                  label: 'Alquiler de Cancha',
                  icon: Icons.sports_tennis,
                  onChanged: (_) => _markAsChanged(),
                ),
              ],
            ),
            const Gap(16),
            _buildAccordionSection(
              context,
              title: 'Horarios de Operación',
              icon: Icons.access_time,
              isExpanded: _isOperatingHoursExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isOperatingHoursExpanded = value;
                });
              },
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        context,
                        label: 'Hora de Apertura',
                        time: _openTime,
                        onTap: () => _selectTime(true),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildTimeField(
                        context,
                        label: 'Hora de Cierre',
                        time: _closeTime,
                        onTap: () => _selectTime(false),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                Text(
                  'Días de la Semana',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Gap(12),
                _buildDaysSelector(context),
                const Gap(16),
                ElevatedButton.icon(
                  onPressed: _isSavingOperatingHours
                      ? null
                      : _saveOperatingHours,
                  icon: _isSavingOperatingHours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSavingOperatingHours
                        ? 'Guardando...'
                        : 'Guardar Horarios',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            _buildAccordionSection(
              context,
              title: 'Branding',
              icon: Icons.palette,
              isExpanded: _isBrandingExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isBrandingExpanded = value;
                });
              },
              children: [
                _buildTextField(
                  controller: _logoUrlController,
                  label: 'URL del Logo',
                  icon: Icons.image,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildTextField(
                  controller: _primaryColorController,
                  label: 'Color Primario (hex, ej: #2E7D32)',
                  icon: Icons.color_lens,
                  onChanged: (_) => _markAsChanged(),
                ),
                const Gap(16),
                _buildTextField(
                  controller: _secondaryColorController,
                  label: 'Color Secundario (hex, ej: #4CAF50)',
                  icon: Icons.color_lens_outlined,
                  onChanged: (_) => _markAsChanged(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isExpanded ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Icon(
            icon,
            color: isExpanded
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isExpanded ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: isExpanded
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
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
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
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
        if (value == null || value.isEmpty) {
          return 'Ingresa un precio';
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Precio inválido';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: colorScheme.primary, size: 20),
                const Gap(8),
                Text(
                  time.format(context),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final days = [
      {'value': 0, 'label': 'Dom'},
      {'value': 1, 'label': 'Lun'},
      {'value': 2, 'label': 'Mar'},
      {'value': 3, 'label': 'Mié'},
      {'value': 4, 'label': 'Jue'},
      {'value': 5, 'label': 'Vie'},
      {'value': 6, 'label': 'Sáb'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final dayValue = day['value'] as int;
        final isSelected = _selectedDays.contains(dayValue);
        return FilterChip(
          label: Text(day['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayValue);
              } else {
                _selectedDays.remove(dayValue);
              }
              _selectedDays.sort();
            });
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
          backgroundColor: colorScheme.surfaceContainerHighest,
        );
      }).toList(),
    );
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? _openTime : _closeTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
          // Ensure close time is after open time
          if (_closeTime.hour < picked.hour ||
              (_closeTime.hour == picked.hour &&
                  _closeTime.minute <= picked.minute)) {
            _closeTime = TimeOfDay(
              hour: picked.hour,
              minute: (picked.minute + 1) % 60,
            );
            if (_closeTime.minute == 0) {
              _closeTime = TimeOfDay(
                hour: (_closeTime.hour + 1) % 24,
                minute: 0,
              );
            }
          }
        } else {
          _closeTime = picked;
          // Ensure open time is before close time
          if (_openTime.hour > picked.hour ||
              (_openTime.hour == picked.hour &&
                  _openTime.minute >= picked.minute)) {
            _openTime = TimeOfDay(
              hour: picked.hour,
              minute: (picked.minute - 1 + 60) % 60,
            );
            if (_openTime.minute == 59) {
              _openTime = TimeOfDay(
                hour: (_openTime.hour - 1 + 24) % 24,
                minute: 59,
              );
            }
          }
        }
      });
    }
  }

  Future<void> _saveOperatingHours() async {
    setState(() {
      _isSavingOperatingHours = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      await service.updateOperatingHours(
        open: _formatTimeString(_openTime),
        close: _formatTimeString(_closeTime),
        daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
      );

      // Refresh tenant info
      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horarios de operación guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar horarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOperatingHours = false;
        });
      }
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Gap(4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      final currentTenant = ref.read(tenantInfoProvider).value;

      if (currentTenant == null) {
        throw Exception('No se pudo cargar la configuración actual');
      }

      // Build base pricing from form fields
      final basePricing = BasePricingModel(
        individualClass: double.parse(_individualPriceController.text),
        groupClass: double.parse(_groupPriceController.text),
        courtRental: double.parse(_courtRentalController.text),
      );

      // Build config with existing data and new pricing
      final existingConfig = currentTenant.config ?? const TenantConfigData();
      final updatedConfig = TenantConfigData(
        logo: existingConfig.logo,
        primaryColor: existingConfig.primaryColor,
        secondaryColor: existingConfig.secondaryColor,
        basePricing: basePricing,
        operatingHours: existingConfig.operatingHours,
      );

      await service.updateTenantConfig(
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        domain: _domainController.text.trim().isEmpty
            ? null
            : _domainController.text.trim(),
        config: updatedConfig,
      );

      // Refresh tenant info
      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
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
