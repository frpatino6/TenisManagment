import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/tournament_model.dart';
import '../providers/group_stage_provider.dart';
import '../providers/tournaments_provider.dart';

/// Pantalla para configurar la fase de grupos de un torneo.
///
/// Permite al organizador:
/// - Seleccionar número de grupos
/// - Seleccionar jugadores que avanzan por grupo
/// - Seleccionar método de seeding (RANKING/RANDOM)
/// - Generar grupos automáticamente
class GroupStageConfigScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String categoryId;
  final int totalParticipants;

  const GroupStageConfigScreen({
    super.key,
    required this.tournamentId,
    required this.categoryId,
    required this.totalParticipants,
  });

  @override
  ConsumerState<GroupStageConfigScreen> createState() =>
      _GroupStageConfigScreenState();
}

class _GroupStageConfigScreenState
    extends ConsumerState<GroupStageConfigScreen> {
  int _numberOfGroups = 2;
  int _playersAdvancingPerGroup = 2;
  SeedingMethod _seedingMethod = SeedingMethod.ranking;
  bool _isGenerating = false;

  List<int> get _validGroupCounts {
    // Solo permitir divisiones que resulten en grupos balanceados
    final counts = <int>[];
    for (int i = 2; i <= 8; i++) {
      if (widget.totalParticipants % i == 0 ||
          widget.totalParticipants ~/ i >= 3) {
        counts.add(i);
      }
    }
    return counts;
  }

  int get _playersPerGroup => widget.totalParticipants ~/ _numberOfGroups;

  List<int> get _validAdvancingCounts {
    // Jugadores que avanzan no puede ser mayor que jugadores por grupo
    final maxAdvancing = _playersPerGroup - 1;
    return List.generate(maxAdvancing.clamp(1, 4), (index) => index + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Fase de Grupos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Torneo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Total de participantes',
                      '${widget.totalParticipants}',
                    ),
                    _buildInfoRow('Jugadores por grupo', '$_playersPerGroup'),
                    _buildInfoRow(
                      'Total clasificados',
                      '${_numberOfGroups * _playersAdvancingPerGroup}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Configuración
            Text(
              'Configuración de Grupos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Número de grupos
            _buildDropdownField(
              label: 'Número de Grupos',
              value: _numberOfGroups,
              items: _validGroupCounts,
              onChanged: (value) {
                setState(() {
                  _numberOfGroups = value!;
                  // Ajustar jugadores que avanzan si es necesario
                  if (_playersAdvancingPerGroup > _playersPerGroup - 1) {
                    _playersAdvancingPerGroup = (_playersPerGroup - 1).clamp(
                      1,
                      4,
                    );
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Jugadores que avanzan
            _buildDropdownField(
              label: 'Jugadores que Avanzan por Grupo',
              value: _playersAdvancingPerGroup,
              items: _validAdvancingCounts,
              onChanged: (value) {
                setState(() {
                  _playersAdvancingPerGroup = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Método de seeding
            _buildSeedingMethodField(),

            const SizedBox(height: 24),

            // Información de ayuda
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los grupos se generarán automáticamente. Podrás ajustar manualmente los participantes antes de bloquear.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de generar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateGroups,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generando...' : 'Generar Grupos',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text('$item'));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSeedingMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Método de Seeding', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        RadioListTile<SeedingMethod>(
          title: const Text('Por Ranking (ELO)'),
          subtitle: const Text('Distribuye jugadores balanceando ELO'),
          value: SeedingMethod.ranking,
          groupValue: _seedingMethod,
          onChanged: (value) {
            setState(() {
              _seedingMethod = value!;
            });
          },
        ),
        RadioListTile<SeedingMethod>(
          title: const Text('Aleatorio'),
          subtitle: const Text('Distribuye jugadores aleatoriamente'),
          value: SeedingMethod.random,
          groupValue: _seedingMethod,
          onChanged: (value) {
            setState(() {
              _seedingMethod = value!;
            });
          },
        ),
      ],
    );
  }

  Future<void> _generateGroups() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final generator = ref.read(groupStageGeneratorProvider.notifier);
      await generator.generateGroups(
        tournamentId: widget.tournamentId,
        categoryId: widget.categoryId,
        numberOfGroups: _numberOfGroups,
        playersAdvancingPerGroup: _playersAdvancingPerGroup,
        seedingMethod: _seedingMethod,
      );

      if (!mounted) return;

      // Invalidar aquí en la UI donde sabemos que estamos montados
      ref.invalidate(tournamentDetailProvider(widget.tournamentId));

      // Navegar a pantalla de gestión
      context.pushReplacement(
        '/tournaments/${widget.tournamentId}/categories/${widget.categoryId}/groups',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar grupos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
