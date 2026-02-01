import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/dtos/create_tournament_dto.dart';
import '../../domain/dtos/update_tournament_dto.dart';
import '../../domain/models/tournament_model.dart';
import '../providers/tournaments_provider.dart';
import '../../../../core/widgets/loading_screen.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  final TournamentModel? tournament;

  const CreateTournamentScreen({super.key, this.tournament});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  late final List<_CategoryFormItem> _categories;

  @override
  void initState() {
    super.initState();
    if (widget.tournament != null) {
      final t = widget.tournament!;
      _nameController.text = t.name;
      _descriptionController.text = t.description ?? '';
      _startDate = t.startDate;
      _endDate = t.endDate;
      _categories = t.categories
          .map(
            (c) => _CategoryFormItem(
              id: c.id,
              name: c.name,
              gender: c.gender,
              format: c.format,
              hasParticipants: c.participants.isNotEmpty,
              groupStageConfig:
                  c.groupStageConfig ??
                  const GroupStageConfig(
                    numberOfGroups: 0,
                    playersAdvancingPerGroup: 0,
                    seedingMethod: SeedingMethod.ranking,
                  ),
            ),
          )
          .toList();
    } else {
      _categories = [
        _CategoryFormItem(
          name: 'Single Masculino A',
          gender: CategoryGender.male,
          format: TournamentFormat.singleElimination,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(_CategoryFormItem());
    });
  }

  void _removeCategory(int index) {
    if (_categories.length > 1) {
      setState(() {
        _categories.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione las fechas del torneo'),
        ),
      );
      return;
    }

    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.tournament != null) {
        final dto = UpdateTournamentDto(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          categories: _categories
              .map(
                (c) => UpdateCategoryDto(
                  id: c.id,
                  name: c.name,
                  gender: c.gender,
                  format: c.format,
                  groupStageConfig: c.format == TournamentFormat.hybrid
                      ? c.groupStageConfig
                      : null,
                ),
              )
              .toList(),
        );

        await ref
            .read(tournamentsProvider.notifier)
            .updateTournament(widget.tournament!.id, dto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Torneo actualizado exitosamente')),
          );
          context.pop();
        }
      } else {
        final dto = CreateTournamentDto(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          categories: _categories
              .map(
                (c) => CreateCategoryDto(
                  name: c.name,
                  gender: c.gender,
                  format: c.format,
                  groupStageConfig: c.format == TournamentFormat.hybrid
                      ? c.groupStageConfig
                      : null,
                ),
              )
              .toList(),
        );

        await ref.read(tournamentsProvider.notifier).create(dto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Torneo creado exitosamente')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tournament != null
                  ? 'Error al actualizar: $e'
                  : 'Error al crear: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tournament == null ? 'Crear Torneo' : 'Editar Torneo',
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: widget.tournament == null
            ? 'Creando torneo...'
            : 'Actualizando torneo...',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Información General',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Torneo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              Text(
                'Fechas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Inicio'),
                      subtitle: Text(
                        _startDate == null
                            ? 'Seleccionar'
                            : dateFormat.format(_startDate!),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: _selectStartDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fin'),
                      subtitle: Text(
                        _endDate == null
                            ? 'Seleccionar'
                            : dateFormat.format(_endDate!),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categorías',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    tooltip: 'Agregar Categoría',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryItem(index, category, theme),
                );
              }),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: Text(
                  widget.tournament == null
                      ? 'GUARDAR TORNEO'
                      : 'ACTUALIZAR TORNEO',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    int index,
    _CategoryFormItem item,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Categoría',
                      hintText: 'Ej: 4ta Categoría',
                    ),
                    onChanged: (val) => item.name = val,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Requerido' : null,
                  ),
                ),
                if (_categories.length > 1)
                  IconButton(
                    onPressed: () => _removeCategory(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<CategoryGender>(
              segments: const [
                ButtonSegment(value: CategoryGender.male, label: Text('Masc')),
                ButtonSegment(value: CategoryGender.female, label: Text('Fem')),
                ButtonSegment(value: CategoryGender.mixed, label: Text('Mix')),
              ],
              selected: {item.gender},
              onSelectionChanged: (Set<CategoryGender> selection) {
                setState(() {
                  item.gender = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TournamentFormat>(
              value: item.format,
              decoration: const InputDecoration(
                labelText: 'Formato del Torneo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: TournamentFormat.singleElimination,
                  child: Text('Eliminación Simple'),
                ),
                DropdownMenuItem(
                  value: TournamentFormat.hybrid,
                  child: Text('Híbrido (Grupos + Eliminación)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    item.format = value;
                  });
                }
              },
            ),
            if (item.format == TournamentFormat.hybrid) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Configuración de Fase de Grupos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.groupStageConfig.numberOfGroups
                          .toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nº de Grupos',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          item.groupStageConfig = GroupStageConfig(
                            numberOfGroups: int.tryParse(val) ?? 0,
                            playersAdvancingPerGroup:
                                item.groupStageConfig.playersAdvancingPerGroup,
                            seedingMethod: item.groupStageConfig.seedingMethod,
                            pointsForWin: item.groupStageConfig.pointsForWin,
                            pointsForDraw: item.groupStageConfig.pointsForDraw,
                            pointsForLoss: item.groupStageConfig.pointsForLoss,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: item
                          .groupStageConfig
                          .playersAdvancingPerGroup
                          .toString(),
                      decoration: const InputDecoration(
                        labelText: 'Clasifican x G.',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          item.groupStageConfig = GroupStageConfig(
                            numberOfGroups:
                                item.groupStageConfig.numberOfGroups,
                            playersAdvancingPerGroup: int.tryParse(val) ?? 0,
                            seedingMethod: item.groupStageConfig.seedingMethod,
                            pointsForWin: item.groupStageConfig.pointsForWin,
                            pointsForDraw: item.groupStageConfig.pointsForDraw,
                            pointsForLoss: item.groupStageConfig.pointsForLoss,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SeedingMethod>(
                value: item.groupStageConfig.seedingMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de Sorteo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SeedingMethod.ranking,
                    child: Text('Por Ranking (Siembra)'),
                  ),
                  DropdownMenuItem(
                    value: SeedingMethod.random,
                    child: Text('Al Azar'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      item.groupStageConfig = GroupStageConfig(
                        numberOfGroups: item.groupStageConfig.numberOfGroups,
                        playersAdvancingPerGroup:
                            item.groupStageConfig.playersAdvancingPerGroup,
                        seedingMethod: val,
                        pointsForWin: item.groupStageConfig.pointsForWin,
                        pointsForDraw: item.groupStageConfig.pointsForDraw,
                        pointsForLoss: item.groupStageConfig.pointsForLoss,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Puntaje',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.groupStageConfig.pointsForWin
                          .toString(),
                      decoration: const InputDecoration(
                        labelText: 'Victoria',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          item.groupStageConfig = GroupStageConfig(
                            numberOfGroups:
                                item.groupStageConfig.numberOfGroups,
                            playersAdvancingPerGroup:
                                item.groupStageConfig.playersAdvancingPerGroup,
                            seedingMethod: item.groupStageConfig.seedingMethod,
                            pointsForWin: int.tryParse(val) ?? 3,
                            pointsForDraw: item.groupStageConfig.pointsForDraw,
                            pointsForLoss: item.groupStageConfig.pointsForLoss,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.groupStageConfig.pointsForDraw
                          .toString(),
                      decoration: const InputDecoration(
                        labelText: 'Empate',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          item.groupStageConfig = GroupStageConfig(
                            numberOfGroups:
                                item.groupStageConfig.numberOfGroups,
                            playersAdvancingPerGroup:
                                item.groupStageConfig.playersAdvancingPerGroup,
                            seedingMethod: item.groupStageConfig.seedingMethod,
                            pointsForWin: item.groupStageConfig.pointsForWin,
                            pointsForDraw: int.tryParse(val) ?? 1,
                            pointsForLoss: item.groupStageConfig.pointsForLoss,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.groupStageConfig.pointsForLoss
                          .toString(),
                      decoration: const InputDecoration(
                        labelText: 'Derrota',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          item.groupStageConfig = GroupStageConfig(
                            numberOfGroups:
                                item.groupStageConfig.numberOfGroups,
                            playersAdvancingPerGroup:
                                item.groupStageConfig.playersAdvancingPerGroup,
                            seedingMethod: item.groupStageConfig.seedingMethod,
                            pointsForWin: item.groupStageConfig.pointsForWin,
                            pointsForDraw: item.groupStageConfig.pointsForDraw,
                            pointsForLoss: int.tryParse(val) ?? 0,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryFormItem {
  String? id;
  String name;
  CategoryGender gender;
  TournamentFormat format;
  bool hasParticipants;
  GroupStageConfig groupStageConfig;

  _CategoryFormItem({
    this.id,
    this.name = '',
    this.gender = CategoryGender.mixed,
    this.format = TournamentFormat.singleElimination,
    this.hasParticipants = false,
    this.groupStageConfig = const GroupStageConfig(
      numberOfGroups: 4,
      playersAdvancingPerGroup: 2,
      seedingMethod: SeedingMethod.ranking,
      pointsForWin: 3,
      pointsForDraw: 1,
      pointsForLoss: 0,
    ),
  });
}
