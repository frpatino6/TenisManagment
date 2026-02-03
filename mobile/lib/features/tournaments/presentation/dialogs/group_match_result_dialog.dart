import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/group_stage_model.dart';
import '../providers/group_stage_provider.dart';

/// Diálogo para registrar el resultado de un partido de grupo.
class GroupMatchResultDialog extends ConsumerStatefulWidget {
  final String tournamentId;
  final String categoryId;
  final GroupStageMatchModel match;
  final Map<String, String> playerNames;

  const GroupMatchResultDialog({
    super.key,
    required this.tournamentId,
    required this.categoryId,
    required this.match,
    required this.playerNames,
  });

  @override
  ConsumerState<GroupMatchResultDialog> createState() =>
      _GroupMatchResultDialogState();
}

class _GroupMatchResultDialogState
    extends ConsumerState<GroupMatchResultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  String? _selectedWinnerId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Resultado'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del partido (Header Premium)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.playerNames[widget.match.player1Id] ??
                                'Jugador 1',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.playerNames[widget.match.player2Id] ??
                                'Jugador 2',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seleccionar ganador
              Text(
                'Ganador',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedWinnerId,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  hintText: 'Seleccionar ganador',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: widget.match.player1Id,
                    child: Text(
                      widget.playerNames[widget.match.player1Id] ?? 'Jugador 1',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  DropdownMenuItem(
                    value: widget.match.player2Id,
                    child: Text(
                      widget.playerNames[widget.match.player2Id] ?? 'Jugador 2',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWinnerId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debe seleccionar un ganador';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Ingresar score
              Text(
                'Resultado',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ScoreInputFormatter(),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  hintText: 'Ingrese números: ej 6264',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  helperText:
                      'Escriba solo los números, el formato es automático',
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debe ingresar el resultado';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Ejemplos de formato
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.withValues(alpha: 0.05)
                      : Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ejemplos de formato:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildExampleRow('6-4 6-3', '(2 sets)'),
                    const SizedBox(height: 4),
                    _buildExampleRow('6-4 3-6 7-5', '(3 sets)'),
                    const SizedBox(height: 4),
                    _buildExampleRow('7-6 6-4', '(tie-break)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitResult,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildExampleRow(String formula, String description) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: Colors.blue)),
        Text(
          formula,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final generator = ref.read(groupStageGeneratorProvider.notifier);
      await generator.recordMatchResult(
        tournamentId: widget.tournamentId,
        categoryId: widget.categoryId,
        matchId: widget.match.id,
        winnerId: _selectedWinnerId!,
        score: _scoreController.text.trim(),
      );

      if (!mounted) return;

      // Invalidar provider para refrescar datos
      ref.invalidate(groupStageProvider);

      Navigator.of(context).pop(true); // Retornar true para indicar éxito

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultado registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar resultado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/// Formateador para convertir "6264" en "6-2, 6-4"
class _ScoreInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 0 || i == 2) {
        if (text.length > i + 1) {
          buffer.write('-');
        }
      } else if (i == 1) {
        if (text.length > i + 1) {
          buffer.write(', ');
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
