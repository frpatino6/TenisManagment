import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/pricing_repository.dart';
import '../../infrastructure/repositories/pricing_repository_impl.dart';
import '../../domain/services/pricing_service.dart' show PricingResponse;

class PricingConfigScreen extends StatefulWidget {
  const PricingConfigScreen({super.key});

  @override
  State<PricingConfigScreen> createState() => _PricingConfigScreenState();
}

class _PricingConfigScreenState extends State<PricingConfigScreen> {
  final PricingRepository _pricingRepository = PricingRepositoryImpl();
  final _formKey = GlobalKey<FormState>();

  final _individualController = TextEditingController();
  final _groupController = TextEditingController();
  final _courtController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  PricingResponse? _pricingData;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _individualController.dispose();
    _groupController.dispose();
    _courtController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataMap = await _pricingRepository.getMyPricing();
      final data = PricingResponse.fromJson(dataMap);

      setState(() {
        _pricingData = data;
        _individualController.text = data.pricing.individualClass
            .toStringAsFixed(0);
        _groupController.text = data.pricing.groupClass.toStringAsFixed(0);
        _courtController.text = data.pricing.courtRental.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar precios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dataMap = await _pricingRepository.updateMyPricing(
        individualClass: double.parse(_individualController.text),
        groupClass: double.parse(_groupController.text),
        courtRental: double.parse(_courtController.text),
      );
      final data = PricingResponse.fromJson(dataMap);

      setState(() {
        _pricingData = data;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precios actualizados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPricing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Restablecer Precios',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Deseas restablecer tus precios a los valores base del sistema?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restablecer', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dataMap = await _pricingRepository.resetMyPricing();
      final data = PricingResponse.fromJson(dataMap);

      setState(() {
        _pricingData = data;
        _individualController.text = data.pricing.individualClass
            .toStringAsFixed(0);
        _groupController.text = data.pricing.groupClass.toStringAsFixed(0);
        _courtController.text = data.pricing.courtRental.toStringAsFixed(0);
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precios restablecidos a valores base'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configurar Precios',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_pricingData?.hasCustomPricing == true)
            IconButton(
              onPressed: _isSaving ? null : _resetPricing,
              icon: const Icon(Icons.restore),
              tooltip: 'Restablecer precios base',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pricingData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                _pricingData!.hasCustomPricing
                                    ? 'Estás usando precios personalizados. Puedes restablecerlos a los valores base usando el botón de arriba.'
                                    : 'Estás usando los precios base del sistema. Personalízalos según tu experiencia.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(24),
                    ],

                    Text(
                      'Clase Individual',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _individualController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Precio por hora',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                        hintText:
                            _pricingData?.basePricing.individualClass
                                .toStringAsFixed(0) ??
                            '50000',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.inter(),
                        hintStyle: GoogleFonts.inter(),
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
                    ),
                    const Gap(24),

                    Text(
                      'Clase Grupal',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _groupController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Precio por hora',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                        hintText:
                            _pricingData?.basePricing.groupClass
                                .toStringAsFixed(0) ??
                            '35000',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.inter(),
                        hintStyle: GoogleFonts.inter(),
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
                    ),
                    const Gap(24),

                    Text(
                      'Alquiler de Cancha',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _courtController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Precio por hora',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                        hintText:
                            _pricingData?.basePricing.courtRental
                                .toStringAsFixed(0) ??
                            '25000',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.inter(),
                        hintStyle: GoogleFonts.inter(),
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
                    ),
                    const Gap(32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _savePricing,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Precios',
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
}
