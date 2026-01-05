import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/tenant_court_model.dart';
import '../../domain/services/tenant_admin_service.dart';
import '../providers/tenant_admin_provider.dart';

class TenantEditCourtScreen extends ConsumerStatefulWidget {
  final String courtId;
  const TenantEditCourtScreen({super.key, required this.courtId});

  @override
  ConsumerState<TenantEditCourtScreen> createState() =>
      _TenantEditCourtScreenState();
}

class _TenantEditCourtScreenState extends ConsumerState<TenantEditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  String? _selectedType;
  List<String> _selectedFeatures = [];
  bool? _isActive;
  bool _isLoading = false;
  bool _isInitialLoading = true;

  final List<String> _availableFeatures = [
    'Techada',
    'Iluminación',
    'Vestuarios',
    'Estacionamiento',
    'Cafetería',
    'WiFi',
    'Aire acondicionado',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadCourtData();
  }

  Future<void> _loadCourtData() async {
    try {
      final courts = await ref.read(tenantCourtsProvider.future);
      final court = courts.firstWhere((c) => c.id == widget.courtId);

      setState(() {
        _nameController.text = court.name;
        _priceController.text = court.price.toString();
        _descriptionController.text = court.description ?? '';
        _selectedType = court.type;
        _selectedFeatures = List.from(court.features);
        _isActive = court.isActive;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cancha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Cancha'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cancha'),
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
                'Información de la Cancha',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Gap(24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Cancha',
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
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cancha',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'tennis', child: Text('Tenis')),
                  DropdownMenuItem(value: 'padel', child: Text('Padel')),
                  DropdownMenuItem(value: 'multi', child: Text('Multi-deporte')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const Gap(16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio por Hora',
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const Gap(16),
              SwitchListTile(
                title: const Text('Cancha Activa'),
                subtitle: const Text('Si está inactiva, no aparecerá en las reservas'),
                value: _isActive ?? true,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),
              const Gap(24),
              Text(
                'Características',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFeatures.map((feature) {
                  final isSelected = _selectedFeatures.contains(feature);
                  return FilterChip(
                    label: Text(feature),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFeatures.add(feature);
                        } else {
                          _selectedFeatures.remove(feature);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
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
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      final request = UpdateCourtRequest(
        name: _nameController.text.trim(),
        type: _selectedType,
        price: double.tryParse(_priceController.text),
        isActive: _isActive,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        features: _selectedFeatures,
      );

      await service.updateCourt(widget.courtId, request);

      ref.invalidate(tenantCourtsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancha actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar cancha: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

