import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_court_model.dart';
import '../../domain/services/tenant_admin_service.dart';
import 'tenant_create_court_screen.dart';
import 'tenant_edit_court_screen.dart';

class TenantCourtsListScreen extends ConsumerStatefulWidget {
  const TenantCourtsListScreen({super.key});

  @override
  ConsumerState<TenantCourtsListScreen> createState() =>
      _TenantCourtsListScreenState();
}

class _TenantCourtsListScreenState extends ConsumerState<TenantCourtsListScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all'; // 'all', 'tennis', 'padel', 'multi'
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final courts = ref.watch(tenantCourtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canchas'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar cancha...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: _filterType == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterType = 'all');
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Tenis'),
                        selected: _filterType == 'tennis',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterType = 'tennis');
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Padel'),
                        selected: _filterType == 'padel',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterType = 'padel');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterStatus = 'all');
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Activas'),
                        selected: _filterStatus == 'active',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterStatus = 'active');
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Inactivas'),
                        selected: _filterStatus == 'inactive',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterStatus = 'inactive');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: courts.when(
              data: (courtsList) {
                final filtered = _filterCourts(courtsList);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_tennis_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const Gap(16),
                        Text(
                          'No se encontraron canchas',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tenantCourtsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final court = filtered[index];
                      return _buildCourtCard(context, court);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(tenantCourtsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/tenant-create-court');
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Cancha'),
      ),
    );
  }

  List<TenantCourtModel> _filterCourts(List<TenantCourtModel> courts) {
    var filtered = courts;

    // Filter by type
    if (_filterType != 'all') {
      filtered = filtered.where((c) => c.type == _filterType).toList();
    }

    // Filter by status
    if (_filterStatus == 'active') {
      filtered = filtered.where((c) => c.isActive).toList();
    } else if (_filterStatus == 'inactive') {
      filtered = filtered.where((c) => !c.isActive).toList();
    }

    // Filter by search
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(searchQuery))
          .toList();
    }

    return filtered;
  }

  Widget _buildCourtCard(BuildContext context, TenantCourtModel court) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/tenant-edit-court/${court.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis,
                  color: colorScheme.primary,
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
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            court.isActive ? 'Activa' : 'Inactiva',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: court.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            court.typeDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          court.formattedPrice,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Text(' / hora'),
                      ],
                    ),
                    if (court.description != null && court.description!.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        court.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  _handleMenuAction(context, court, value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        Gap(8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: court.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          court.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        const Gap(8),
                        Text(court.isActive ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        Gap(8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
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

  Future<void> _handleMenuAction(
    BuildContext context,
    TenantCourtModel court,
    String action,
  ) async {
    try {
      final service = ref.read(tenantAdminServiceProvider);
      if (action == 'edit') {
        context.push('/tenant-edit-court/${court.id}');
      } else if (action == 'activate' || action == 'deactivate') {
        await service.updateCourt(
          court.id,
          UpdateCourtRequest(isActive: action == 'activate'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'activate'
                  ? 'Cancha activada exitosamente'
                  : 'Cancha desactivada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(tenantCourtsProvider);
      } else if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Cancha'),
            content: Text(
              '¿Estás seguro de que quieres eliminar la cancha "${court.name}"? Esta acción no se puede deshacer.',
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
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await service.deleteCourt(court.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cancha eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(tenantCourtsProvider);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

