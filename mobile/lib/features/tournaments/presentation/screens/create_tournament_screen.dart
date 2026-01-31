import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/dtos/create_tournament_dto.dart';
import '../../domain/models/tournament_model.dart';
import '../providers/tournaments_provider.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

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

  final List<_CategoryFormItem> _categories = [
    _CategoryFormItem(name: 'Single Masculino A', gender: CategoryGender.male),
  ];

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

    final dto = CreateTournamentDto(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      startDate: _startDate!,
      endDate: _endDate!,
      categories: _categories
          .map((c) => CreateCategoryDto(name: c.name, gender: c.gender))
          .toList(),
    );

    try {
      await ref.read(tournamentsProvider.notifier).create(dto);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Torneo creado exitosamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Torneo')),
      body: Form(
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
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text(
                'GUARDAR TORNEO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
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
          ],
        ),
      ),
    );
  }
}

class _CategoryFormItem {
  String name;
  CategoryGender gender;

  _CategoryFormItem({this.name = '', this.gender = CategoryGender.mixed});
}
