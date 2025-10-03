import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AnalyticsFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final String? selectedServiceType;
  final String? selectedStatus;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String?> onServiceTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback? onRefresh;

  const AnalyticsFilterBar({
    super.key,
    required this.selectedPeriod,
    this.selectedServiceType,
    this.selectedStatus,
    required this.onPeriodChanged,
    required this.onServiceTypeChanged,
    required this.onStatusChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
                const Gap(8),
                Text(
                  'Filtros',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar datos',
                  ),
              ],
            ),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  context,
                  'Período',
                  selectedPeriod,
                  _getPeriodOptions(),
                  (value) => onPeriodChanged(value ?? 'month'),
                ),
                _buildFilterChip(
                  context,
                  'Tipo de Servicio',
                  selectedServiceType,
                  _getServiceTypeOptions(),
                  onServiceTypeChanged,
                ),
                _buildFilterChip(
                  context,
                  'Estado',
                  selectedStatus,
                  _getStatusOptions(),
                  onStatusChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip<T>(
    BuildContext context,
    String label,
    T? selectedValue,
    List<FilterOption<T>> options,
    ValueChanged<T?> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: [
              // Clear option
              if (selectedValue != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: false,
                    onSelected: (_) => onChanged(null),
                    backgroundColor: colorScheme.surfaceVariant,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.bodySmall,
                  ),
                ),
              // Options
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option.label),
                    selected: selectedValue == option.value,
                    onSelected: (_) => onChanged(option.value),
                    backgroundColor: colorScheme.surfaceVariant,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: selectedValue == option.value
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FilterOption<String>> _getPeriodOptions() {
    return [
      FilterOption('week', 'Esta semana'),
      FilterOption('month', 'Este mes'),
      FilterOption('quarter', 'Este trimestre'),
      FilterOption('year', 'Este año'),
    ];
  }

  List<FilterOption<String>> _getServiceTypeOptions() {
    return [
      FilterOption('individual_class', 'Clase Individual'),
      FilterOption('group_class', 'Clase Grupal'),
      FilterOption('court_rental', 'Alquiler de Cancha'),
    ];
  }

  List<FilterOption<String>> _getStatusOptions() {
    return [
      FilterOption('confirmed', 'Confirmado'),
      FilterOption('completed', 'Completado'),
      FilterOption('cancelled', 'Cancelado'),
      FilterOption('pending', 'Pendiente'),
    ];
  }
}

class FilterOption<T> {
  final T value;
  final String label;

  FilterOption(this.value, this.label);
}
