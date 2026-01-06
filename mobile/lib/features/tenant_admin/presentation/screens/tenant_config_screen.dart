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
  // Operating hours: Map<dayOfWeek (0-6), {open: TimeOfDay, close: TimeOfDay}>
  final Map<int, ({TimeOfDay open, TimeOfDay close})> _daySchedules = {};
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
    _daySchedules.clear();
    if (operatingHours != null &&
        operatingHours.schedule != null &&
        operatingHours.schedule!.isNotEmpty) {
      // New format: schedule array
      for (final daySchedule in operatingHours.schedule!) {
        _daySchedules[daySchedule.dayOfWeek] = (
          open: _parseTimeString(daySchedule.open),
          close: _parseTimeString(daySchedule.close),
        );
      }
    } else if (operatingHours?.open != null && operatingHours?.close != null) {
      // Legacy format: single open/close for all selected days
      final openTime = _parseTimeString(operatingHours!.open!);
      final closeTime = _parseTimeString(operatingHours.close!);
      final days = operatingHours.daysOfWeek ?? [0, 1, 2, 3, 4, 5, 6];
      for (final day in days) {
        _daySchedules[day] = (open: openTime, close: closeTime);
      }
    } else {
      // Default: all days 06:00-22:00
      const defaultOpen = TimeOfDay(hour: 6, minute: 0);
      const defaultClose = TimeOfDay(hour: 22, minute: 0);
      for (int day = 0; day < 7; day++) {
        _daySchedules[day] = (open: defaultOpen, close: defaultClose);
      }
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
                  onChanged: (_) {
                    setState(() {}); // Update subtitle
                    _markAsChanged();
                  },
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
              subtitle: _getPricingSubtitle(),
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
              subtitle: _getOperatingHoursSubtitle(),
              onExpansionChanged: (value) {
                setState(() {
                  _isOperatingHoursExpanded = value;
                });
              },
              children: [
                Text(
                  'Configura el horario de operación para cada día de la semana:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(16),
                ...List.generate(7, (index) {
                  final dayOfWeek = index;
                  final dayNames = [
                    'Domingo',
                    'Lunes',
                    'Martes',
                    'Miércoles',
                    'Jueves',
                    'Viernes',
                    'Sábado',
                  ];
                  final schedule = _daySchedules[dayOfWeek];
                  final openTime =
                      schedule?.open ?? const TimeOfDay(hour: 6, minute: 0);
                  final closeTime =
                      schedule?.close ?? const TimeOfDay(hour: 22, minute: 0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayNames[dayOfWeek],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Gap(8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                context,
                                label: 'Apertura',
                                time: openTime,
                                onTap: () => _selectTime(dayOfWeek, true),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: _buildTimeField(
                                context,
                                label: 'Cierre',
                                time: closeTime,
                                onTap: () => _selectTime(dayOfWeek, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
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
              subtitle: _getBrandingSubtitle(),
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
                _buildColorField(
                  controller: _primaryColorController,
                  label: 'Color Primario (hex, ej: #2E7D32)',
                  icon: Icons.color_lens,
                  onChanged: (_) {
                    setState(() {});
                    _markAsChanged();
                  },
                ),
                const Gap(16),
                _buildColorField(
                  controller: _secondaryColorController,
                  label: 'Color Secundario (hex, ej: #4CAF50)',
                  icon: Icons.color_lens_outlined,
                  onChanged: (_) {
                    setState(() {});
                    _markAsChanged();
                  },
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
    String? subtitle,
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
          childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Icon(
            icon,
            color: isExpanded
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
          title: subtitle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isExpanded
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (!isExpanded && subtitle.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                )
              : Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isExpanded
                        ? colorScheme.primary
                        : colorScheme.onSurface,
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

  String _formatPrice(double? price) {
    if (price == null) return '';
    final priceStr = price.toStringAsFixed(0);
    // Add thousand separators
    final reversed = priceStr.split('').reversed.join();
    final withCommas = reversed.replaceAllMapped(
      RegExp(r'.{3}'),
      (match) => '${match.group(0)},',
    );
    final result = withCommas.split('').reversed.join();
    // Remove leading comma if any
    return '\$${result.startsWith(',') ? result.substring(1) : result}';
  }

  String _getPricingSubtitle() {
    final individual = double.tryParse(_individualPriceController.text);
    final group = double.tryParse(_groupPriceController.text);
    final court = double.tryParse(_courtRentalController.text);

    if (individual == null && group == null && court == null) {
      return 'No configurado';
    }

    final List<String> prices = [];
    if (individual != null)
      prices.add('Individual: ${_formatPrice(individual)}');
    if (group != null) prices.add('Grupal: ${_formatPrice(group)}');
    if (court != null) prices.add('Cancha: ${_formatPrice(court)}');

    return prices.join(' • ');
  }

  String _getOperatingHoursSubtitle() {
    if (_daySchedules.isEmpty) return 'No configurado';

    final uniqueSchedules = <String, List<int>>{};
    for (final entry in _daySchedules.entries) {
      final key =
          '${_formatTimeString(entry.value.open)}-${_formatTimeString(entry.value.close)}';
      uniqueSchedules.putIfAbsent(key, () => []).add(entry.key);
    }

    if (uniqueSchedules.length == 1) {
      final schedule = uniqueSchedules.keys.first;
      final days = uniqueSchedules.values.first;
      if (days.length == 7) {
        return 'Todos los días: $schedule';
      }
      const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      final dayNamesStr = days.map((d) => dayNames[d]).join(', ');
      return '$dayNamesStr: $schedule';
    }

    return '${_daySchedules.length} días configurados';
  }

  String _getBrandingSubtitle() {
    final primaryColor = _primaryColorController.text.trim();
    final secondaryColor = _secondaryColorController.text.trim();
    final logo = _logoUrlController.text.trim();

    if (primaryColor.isEmpty && secondaryColor.isEmpty && logo.isEmpty) {
      return 'No configurado';
    }

    final List<String> items = [];
    if (primaryColor.isNotEmpty) items.add('Primario: $primaryColor');
    if (secondaryColor.isNotEmpty) items.add('Secundario: $secondaryColor');
    if (logo.isNotEmpty) items.add('Logo configurado');

    return items.take(2).join(' • ');
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

  Widget _buildColorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorHex = controller.text.trim();
    Color? previewColor;

    // Try to parse hex color
    if (colorHex.isNotEmpty && colorHex.startsWith('#')) {
      try {
        final hex = colorHex.replaceFirst('#', '');
        if (hex.length == 6) {
          previewColor = Color(int.parse('FF$hex', radix: 16));
        }
      } catch (e) {
        // Invalid color, ignore
      }
    }

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: previewColor != null
            ? Container(
                margin: const EdgeInsets.all(8),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              )
            : null,
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

  Future<void> _selectTime(int dayOfWeek, bool isOpenTime) async {
    // Initialize with defaults if not set
    _daySchedules[dayOfWeek] ??= (
      open: const TimeOfDay(hour: 6, minute: 0),
      close: const TimeOfDay(hour: 22, minute: 0),
    );

    final schedule = _daySchedules[dayOfWeek]!;
    final currentTime = isOpenTime ? schedule.open : schedule.close;
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      setState(() {
        final currentSchedule = _daySchedules[dayOfWeek]!;
        if (isOpenTime) {
          // Update open time, ensure close time is after
          final openMinutes = picked.hour * 60 + picked.minute;
          final closeMinutes =
              currentSchedule.close.hour * 60 + currentSchedule.close.minute;

          if (openMinutes >= closeMinutes) {
            // If open is after or equal to close, set close to 1 hour after open
            var newCloseHour = (picked.hour + 1) % 24;
            var newCloseMinute = picked.minute;
            if (newCloseHour == 0 && picked.minute > 0) {
              newCloseHour = 23;
              newCloseMinute = 59;
            }
            _daySchedules[dayOfWeek] = (
              open: picked,
              close: TimeOfDay(hour: newCloseHour, minute: newCloseMinute),
            );
          } else {
            _daySchedules[dayOfWeek] = (
              open: picked,
              close: currentSchedule.close,
            );
          }
        } else {
          // Update close time, ensure open time is before
          final openMinutes =
              currentSchedule.open.hour * 60 + currentSchedule.open.minute;
          final closeMinutes = picked.hour * 60 + picked.minute;

          if (closeMinutes <= openMinutes) {
            // If close is before or equal to open, set open to 1 hour before close
            var newOpenHour = (picked.hour - 1 + 24) % 24;
            var newOpenMinute = picked.minute;
            _daySchedules[dayOfWeek] = (
              open: TimeOfDay(hour: newOpenHour, minute: newOpenMinute),
              close: picked,
            );
          } else {
            _daySchedules[dayOfWeek] = (
              open: currentSchedule.open,
              close: picked,
            );
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

      // Convert _daySchedules to schedule array
      final schedule = _daySchedules.entries.map((entry) {
        return {
          'dayOfWeek': entry.key,
          'open': _formatTimeString(entry.value.open),
          'close': _formatTimeString(entry.value.close),
        };
      }).toList();

      await service.updateOperatingHours(schedule: schedule);

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
