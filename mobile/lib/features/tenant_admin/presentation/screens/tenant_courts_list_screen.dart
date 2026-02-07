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
import '../../domain/models/tenant_court_model.dart';

enum CourtFilter { all, active, inactive }

class TenantCourtsListScreen extends ConsumerStatefulWidget {
  const TenantCourtsListScreen({super.key});

  @override
  ConsumerState<TenantCourtsListScreen> createState() =>
      _TenantCourtsListScreenState();
}

class _TenantCourtsListScreenState
    extends ConsumerState<TenantCourtsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  CourtFilter _selectedFilter = CourtFilter.all;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Timeouts.debounceSearch, () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  Future<void> _refreshCourts() async {
    ref.invalidate(tenantCourtsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final courtsAsync = ref.watch(tenantCourtsProvider);

    final filteredBySearch = ref.watch(
      filteredTenantCourtsProvider(_searchQuery),
    );
    final filteredByStatus = ref.watch(
      filteredTenantCourtsByStatusProvider(
        _selectedFilter == CourtFilter.active
            ? 'active'
            : _selectedFilter == CourtFilter.inactive
            ? 'inactive'
            : 'all',
      ),
    );

    // Combine filters
    final List<TenantCourtModel> finalFilteredList = filteredBySearch
        .where((court) => filteredByStatus.contains(court))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Canchas',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCourts,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, tipo o descripción...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == CourtFilter.all,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = CourtFilter.all;
                          });
                        }
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: GoogleFonts.inter(
                        color: _selectedFilter == CourtFilter.all
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Activas'),
                      selected: _selectedFilter == CourtFilter.active,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = CourtFilter.active;
                          });
                        }
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: GoogleFonts.inter(
                        color: _selectedFilter == CourtFilter.active
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Inactivas'),
                      selected: _selectedFilter == CourtFilter.inactive,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = CourtFilter.inactive;
                          });
                        }
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: GoogleFonts.inter(
                        color: _selectedFilter == CourtFilter.inactive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: courtsAsync.when(
              data: (courts) {
                if (finalFilteredList.isEmpty) {
                  return _buildEmptyState(
                    context,
                    _searchQuery.isNotEmpty ||
                        _selectedFilter != CourtFilter.all,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshCourts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: finalFilteredList.length,
                    itemBuilder: (context, index) {
                      final court = finalFilteredList[index];
                      return _buildCourtCard(context, court);
                    },
                  ),
                );
              },
              loading: () =>
                  const LoadingWidget(message: 'Cargando canchas...'),
              error: (error, stackTrace) {
                if (error is AuthException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.go('/login');
                  });
                  return const SizedBox.shrink();
                }
                return AppErrorWidget.fromError(error, onRetry: _refreshCourts);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/tenant-admin-home/courts/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cancha'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, TenantCourtModel court) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData typeIcon;
    switch (court.type) {
      case 'tennis':
        typeIcon = Icons.sports_tennis;
        break;
      case 'padel':
        typeIcon = Icons.sports_tennis;
        break;
      case 'multi':
        typeIcon = Icons.sports;
        break;
      default:
        typeIcon = Icons.sports_tennis;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: court.isActive
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/tenant-admin-home/courts/${court.id}/edit');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: court.isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  color: court.isActive
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
                            court.name,
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
                            color: court.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            court.isActive ? 'Activa' : 'Inactiva',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: court.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      court.typeDisplayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (court.description != null &&
                        court.description!.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        court.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Gap(8),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const Gap(4),
                        Text(
                          '${court.formattedPrice}/hora',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (court.features.isNotEmpty) ...[
                      const Gap(8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: court.features.take(3).map((feature) {
                          return Chip(
                            label: Text(
                              feature,
                              style: GoogleFonts.inter(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/tenant-admin-home/courts/${court.id}/edit');
                  } else if (value == 'toggle') {
                    _toggleCourtStatus(court);
                  } else if (value == 'delete') {
                    _deleteCourt(context, court);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                        const Gap(8),
                        const Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          court.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                          color: court.isActive ? Colors.red : Colors.green,
                        ),
                        const Gap(8),
                        Text(court.isActive ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        const Gap(8),
                        const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
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
              Icons.sports_tennis_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              hasFilters
                  ? 'No se encontraron canchas'
                  : 'No hay canchas registradas',
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
                  : 'Crea tu primera cancha para comenzar',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const Gap(24),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/tenant-admin-home/courts/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Cancha'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCourtStatus(TenantCourtModel court) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(court.isActive ? 'Desactivar Cancha' : 'Activar Cancha'),
        content: Text(
          court.isActive
              ? '¿Estás seguro de que quieres desactivar "${court.name}"?'
              : '¿Estás seguro de que quieres activar "${court.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(court.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(tenantAdminRepositoryProvider);
      await repository.updateCourt(
        courtId: court.id,
        isActive: !court.isActive,
      );

      // Refresh list
      ref.invalidate(tenantCourtsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              court.isActive
                  ? 'Cancha desactivada exitosamente'
                  : 'Cancha activada exitosamente',
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

  Future<void> _deleteCourt(
    BuildContext context,
    TenantCourtModel court,
  ) async {
    // Guardar el messenger antes de cualquier operación async
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cancha'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${court.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(tenantAdminRepositoryProvider);
      await repository.deleteCourt(court.id);

      // Refresh list
      ref.invalidate(tenantCourtsProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cancha eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
