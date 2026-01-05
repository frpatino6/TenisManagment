import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantProfessorsListScreen extends ConsumerStatefulWidget {
  const TenantProfessorsListScreen({super.key});

  @override
  ConsumerState<TenantProfessorsListScreen> createState() =>
      _TenantProfessorsListScreenState();
}

class _TenantProfessorsListScreenState
    extends ConsumerState<TenantProfessorsListScreen> {
  final _searchController = TextEditingController();
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
    final professors = ref.watch(tenantProfessorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesores'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.push('/tenant-invite-professor');
            },
            tooltip: 'Invitar Profesor',
          ),
        ],
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
                    hintText: 'Buscar por nombre o email...',
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
                        label: const Text('Todos'),
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
                        label: const Text('Activos'),
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
                        label: const Text('Inactivos'),
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
            child: professors.when(
              data: (professorsList) {
                final filtered = _filterProfessors(professorsList);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const Gap(16),
                        Text(
                          'No se encontraron profesores',
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
                    ref.invalidate(tenantProfessorsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final professor = filtered[index];
                      return _buildProfessorCard(context, professor);
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
                      onPressed: () => ref.invalidate(tenantProfessorsProvider),
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
          context.push('/tenant-invite-professor');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Invitar Profesor'),
      ),
    );
  }

  List<TenantProfessorModel> _filterProfessors(
    List<TenantProfessorModel> professors,
  ) {
    var filtered = professors;

    // Filter by status
    if (_filterStatus == 'active') {
      filtered = filtered.where((p) => p.isActive).toList();
    } else if (_filterStatus == 'inactive') {
      filtered = filtered.where((p) => !p.isActive).toList();
    }

    // Filter by search
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchQuery) ||
                p.email.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    return filtered;
  }

  Widget _buildProfessorCard(
    BuildContext context,
    TenantProfessorModel professor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to professor detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  professor.name[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
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
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            professor.isActive ? 'Activo' : 'Inactivo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: professor.isActive
                                  ? Colors.green
                                  : Colors.red,
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
                    if (professor.phone != null) ...[
                      const Gap(4),
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  _handleMenuAction(context, professor, value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: professor.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          professor.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        const Gap(8),
                        Text(professor.isActive ? 'Desactivar' : 'Activar'),
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
    TenantProfessorModel professor,
    String action,
  ) async {
    try {
      final service = ref.read(tenantAdminServiceProvider);
      if (action == 'activate') {
        await service.activateProfessor(professor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profesor activado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (action == 'deactivate') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Desactivar Profesor'),
            content: Text(
              '¿Estás seguro de que quieres desactivar a ${professor.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Desactivar'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await service.deactivateProfessor(professor.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profesor desactivado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      ref.invalidate(tenantProfessorsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
