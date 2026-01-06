import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_professor_model.dart';

enum ProfessorFilter { all, active, inactive }

/// Provider for filtered professors based on search query and filter
final filteredTenantProfessorsProvider =
    Provider.family<List<TenantProfessorModel>, Map<String, dynamic>>((
      ref,
      params,
    ) {
      final professorsAsync = ref.watch(tenantProfessorsProvider);
      final searchQuery = params['searchQuery'] as String? ?? '';
      final filter =
          params['filter'] as ProfessorFilter? ?? ProfessorFilter.all;

      return professorsAsync.when(
        data: (professors) {
          var filtered = professors;

          // Apply filter
          switch (filter) {
            case ProfessorFilter.active:
              filtered = filtered.where((p) => p.isActive).toList();
              break;
            case ProfessorFilter.inactive:
              filtered = filtered.where((p) => !p.isActive).toList();
              break;
            case ProfessorFilter.all:
              break;
          }

          // Apply search
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            filtered = filtered.where((professor) {
              return professor.name.toLowerCase().contains(query) ||
                  professor.email.toLowerCase().contains(query) ||
                  (professor.phone?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return filtered;
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });

class TenantProfessorsListScreen extends ConsumerStatefulWidget {
  const TenantProfessorsListScreen({super.key});

  @override
  ConsumerState<TenantProfessorsListScreen> createState() =>
      _TenantProfessorsListScreenState();
}

class _TenantProfessorsListScreenState
    extends ConsumerState<TenantProfessorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  ProfessorFilter _selectedFilter = ProfessorFilter.all;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final professorsAsync = ref.watch(tenantProfessorsProvider);
    final filteredProfessors = ref.watch(
      filteredTenantProfessorsProvider({
        'searchQuery': _searchQuery,
        'filter': _selectedFilter,
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profesores',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tenantProfessorsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/tenant-admin-home/professors/invite');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Invitar Profesor'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email o teléfono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(Timeouts.debounceSearch, () {
                  setState(() {
                    _searchQuery = value;
                  });
                });
              },
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'Todos',
                    isSelected: _selectedFilter == ProfessorFilter.all,
                    onSelected: () {
                      setState(() {
                        _selectedFilter = ProfessorFilter.all;
                      });
                    },
                  ),
                  const Gap(8),
                  _buildFilterChip(
                    context,
                    label: 'Activos',
                    isSelected: _selectedFilter == ProfessorFilter.active,
                    onSelected: () {
                      setState(() {
                        _selectedFilter = ProfessorFilter.active;
                      });
                    },
                  ),
                  const Gap(8),
                  _buildFilterChip(
                    context,
                    label: 'Inactivos',
                    isSelected: _selectedFilter == ProfessorFilter.inactive,
                    onSelected: () {
                      setState(() {
                        _selectedFilter = ProfessorFilter.inactive;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: professorsAsync.when(
              data: (professors) {
                if (filteredProfessors.isEmpty) {
                  return _buildEmptyState(
                    context,
                    _searchQuery.isNotEmpty ||
                        _selectedFilter != ProfessorFilter.all,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tenantProfessorsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProfessors.length,
                    itemBuilder: (context, index) {
                      final professor = filteredProfessors[index];
                      return _buildProfessorCard(context, professor);
                    },
                  ),
                );
              },
              loading: () =>
                  const LoadingWidget(message: 'Cargando profesores...'),
              error: (error, stackTrace) {
                if (error is AuthException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.go('/login');
                  });
                  return const SizedBox.shrink();
                }
                return AppErrorWidget.fromError(
                  error,
                  onRetry: () => ref.invalidate(tenantProfessorsProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: GoogleFonts.inter(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildProfessorCard(
    BuildContext context,
    TenantProfessorModel professor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: professor.isActive
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to professor detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: professor.isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  color: professor.isActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            professor.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: professor.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            professor.isActive ? 'Activo' : 'Inactivo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: professor.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      professor.email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (professor.phone != null &&
                        professor.phone!.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        professor.phone!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Gap(8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const Gap(4),
                        Text(
                          '${professor.bookingsCount} reservas',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  professor.isActive ? Icons.block : Icons.check_circle,
                  color: professor.isActive
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
                onPressed: () => _toggleProfessorStatus(professor),
                tooltip: professor.isActive ? 'Desactivar' : 'Activar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              hasFilters
                  ? 'No se encontraron profesores'
                  : 'No hay profesores registrados',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Gap(8),
            Text(
              hasFilters
                  ? 'Intenta cambiar los filtros o la búsqueda'
                  : 'Invita profesores para comenzar',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProfessorStatus(TenantProfessorModel professor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          professor.isActive ? 'Desactivar Profesor' : 'Activar Profesor',
        ),
        content: Text(
          professor.isActive
              ? '¿Estás seguro de que quieres desactivar a ${professor.name}?'
              : '¿Estás seguro de que quieres activar a ${professor.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(professor.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(tenantAdminServiceProvider);
      if (professor.isActive) {
        await service.deactivateProfessor(professor.id);
      } else {
        await service.activateProfessor(professor.id);
      }

      // Refresh list
      ref.invalidate(tenantProfessorsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              professor.isActive
                  ? 'Profesor desactivado exitosamente'
                  : 'Profesor activado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
}
