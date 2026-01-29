import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../providers/tenant_admin_provider.dart';

class TenantBookingsSearchAndFilters extends ConsumerWidget {
  final TextEditingController searchController;

  const TenantBookingsSearchAndFilters({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(bookingStatusFilterProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar estudiante...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        ref.read(bookingStudentSearchProvider.notifier).set('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (v) =>
                ref.read(bookingStudentSearchProvider.notifier).set(v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'Todas',
                value: null,
                selected: currentStatus == null,
                onSelected: (v) =>
                    ref.read(bookingStatusFilterProvider.notifier).set(v),
              ),
              const Gap(8),
              _FilterChip(
                label: 'Pendientes',
                value: 'pending',
                selected: currentStatus == 'pending',
                onSelected: (v) =>
                    ref.read(bookingStatusFilterProvider.notifier).set(v),
              ),
              const Gap(8),
              _FilterChip(
                label: 'Confirmadas',
                value: 'confirmed',
                selected: currentStatus == 'confirmed',
                onSelected: (v) =>
                    ref.read(bookingStatusFilterProvider.notifier).set(v),
              ),
              const Gap(8),
              _FilterChip(
                label: 'Completadas',
                value: 'completed',
                selected: currentStatus == 'completed',
                onSelected: (v) =>
                    ref.read(bookingStatusFilterProvider.notifier).set(v),
              ),
              const Gap(8),
              _FilterChip(
                label: 'Canceladas',
                value: 'cancelled',
                selected: currentStatus == 'cancelled',
                onSelected: (v) =>
                    ref.read(bookingStatusFilterProvider.notifier).set(v),
              ),
            ],
          ),
        ),
        const Gap(8),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final void Function(String?) onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) {
        if (s) onSelected(value);
      },
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}
