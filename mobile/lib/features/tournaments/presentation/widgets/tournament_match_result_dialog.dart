import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/bracket_model.dart';

class TournamentMatchResultDialog extends StatefulWidget {
  final BracketMatchModel match;
  final String? player1Name;
  final String? player2Name;

  const TournamentMatchResultDialog({
    super.key,
    required this.match,
    this.player1Name,
    this.player2Name,
  });

  @override
  State<TournamentMatchResultDialog> createState() =>
      _TournamentMatchResultDialogState();
}

class _TournamentMatchResultDialogState
    extends State<TournamentMatchResultDialog> {
  String? _selectedWinnerId;
  final TextEditingController _scoreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedWinnerId = widget.match.winnerId;

    // Auto-selección automática si es un BYE
    if (_selectedWinnerId == null) {
      if (widget.match.player2Id == null) {
        _selectedWinnerId = widget.match.player1Id;
      } else if (widget.match.player1Id == null) {
        _selectedWinnerId = widget.match.player2Id;
      }
    }

    _scoreController.text = widget.match.score ?? '';
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBye =
        widget.match.player2Id == null || widget.match.player1Id == null;

    return AlertDialog(
      title: const Text('Registrar Resultado'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona al ganador:',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Player 1
              if (widget.match.player1Id != null)
                _buildPlayerOption(
                  id: widget.match.player1Id,
                  name: widget.player1Name ?? 'Jugador 1',
                  theme: theme,
                )
              else
                _buildByePlaceholder(theme),

              const SizedBox(height: 8),

              // Player 2
              if (widget.match.player2Id != null)
                _buildPlayerOption(
                  id: widget.match.player2Id,
                  name: widget.player2Name ?? 'Jugador 2',
                  theme: theme,
                )
              else
                _buildByePlaceholder(theme),

              if (!isBye) ...[
                const SizedBox(height: 24),
                Text(
                  'Marcador (ej: 6-2, 6-4):',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scoreController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ScoreInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Ingrese números: ej 6264',
                    helperText:
                        'Escriba solo los números, el formato es automático',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                  ),
                  validator: (value) {
                    if (_selectedWinnerId != null &&
                        (value == null || value.isEmpty)) {
                      return 'Ingrese el marcador';
                    }
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No se requiere marcador para un BYE.',
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildByePlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.disabledColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_off, size: 20),
          SizedBox(width: 12),
          Text('BYE (Avance automático)'),
        ],
      ),
    );
  }

  Widget _buildPlayerOption({
    required String? id,
    required String name,
    required ThemeData theme,
  }) {
    final isSelected = _selectedWinnerId == id;

    return InkWell(
      onTap: id == null ? null : () => setState(() => _selectedWinnerId = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : null,
        ),
        child: Row(
          children: [
            Radio<String?>(
              value: id,
              groupValue: _selectedWinnerId,
              onChanged: (val) => setState(() => _selectedWinnerId = val),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedWinnerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un ganador')),
        );
        return;
      }

      final isBye =
          widget.match.player2Id == null || widget.match.player1Id == null;
      final finalScore = isBye ? 'BYE' : _scoreController.text;

      Navigator.of(
        context,
      ).pop({'winnerId': _selectedWinnerId, 'score': finalScore});
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
