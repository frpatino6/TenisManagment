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
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Profesores',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(tenantProfessorsProvider);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search bar
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar profesor...',
                        hintStyle: GoogleFonts.inter(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
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
                  const Gap(16),

                  // Filter chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStyledFilterChip(
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
                        _buildStyledFilterChip(
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
                        _buildStyledFilterChip(
                          context,
                          label: 'Inactivos',
                          isSelected:
                              _selectedFilter == ProfessorFilter.inactive,
                          onSelected: () {
                            setState(() {
                              _selectedFilter = ProfessorFilter.inactive;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Content
          professorsAsync.when(
            data: (professors) {
              if (filteredProfessors.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    context,
                    _searchQuery.isNotEmpty ||
                        _selectedFilter != ProfessorFilter.all,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final professor = filteredProfessors[index];
                    return _buildProfessorCard(context, professor);
                  }, childCount: filteredProfessors.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: LoadingWidget(message: 'Cargando profesores...'),
            ),
            error: (error, stackTrace) {
              if (error is AuthException) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
                });
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverFillRemaining(
                child: AppErrorWidget.fromError(
                  error,
                  onRetry: () => ref.invalidate(tenantProfessorsProvider),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/tenant-admin-home/professors/invite');
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Invitar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStyledFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        labelStyle: GoogleFonts.inter(
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.transparent,
          ),
        ),
        elevation: 0,
        pressElevation: 1,
        showCheckmark: false, // Cleaner look without checkmark usually
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }

  Widget _buildProfessorCard(
    BuildContext context,
    TenantProfessorModel professor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = professor.name.isNotEmpty
        ? professor.name
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
              .toUpperCase()
        : '?';

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
          context.pushNamed(
            'tenant-admin-professor-details',
            pathParameters: {'id': professor.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Hero(
                        tag: 'professor-avatar-${professor.id}',
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: professor.isActive
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: professor.isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const Gap(16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _capitalizeWords(professor.name),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Gap(8),
                                _buildStatusBadge(context, professor.isActive),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              professor.email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (professor.phone != null &&
                                professor.phone!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  professor.phone!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const Gap(8),

                  // Footer Actions & Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const Gap(6),
                          Text(
                            '${professor.bookingsCount} Reservas',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),

                      // Action Buttons
                      Row(
                        children: [
                          if (professor.isActive)
                            IconButton.filledTonal(
                              constraints: const BoxConstraints(
                                minHeight: 36,
                                minWidth: 36,
                              ),
                              padding: const EdgeInsets.all(8),
                              iconSize: 18,
                              tooltip: 'Desactivar',
                              onPressed: () =>
                                  _toggleProfessorStatus(professor),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.errorContainer,
                                foregroundColor: colorScheme.onErrorContainer,
                              ),
                              icon: const Icon(Icons.block_rounded),
                            )
                          else
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () =>
                                  _toggleProfessorStatus(professor),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                              ),
                              label: const Text('Activar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(6),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const Gap(24),
            Text(
              hasFilters
                  ? 'No se encontraron profesores'
                  : 'No hay profesores registrados',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              hasFilters
                  ? 'Intenta ajustar los filtros de búsqueda'
                  : 'Invita a tu primer profesor para comenzar a gestionar sus horarios.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          professor.isActive ? 'Desactivar Profesor' : 'Activar Profesor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          professor.isActive
              ? '¿Estás seguro de que quieres desactivar a ${professor.name}?\n\nNo podrá recibir nuevas reservas.'
              : '¿Estás seguro de que quieres activar a ${professor.name}?',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: professor.isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              professor.isActive ? 'Desactivar' : 'Activar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
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
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: professor.isActive
                ? Colors.orange.shade800
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
