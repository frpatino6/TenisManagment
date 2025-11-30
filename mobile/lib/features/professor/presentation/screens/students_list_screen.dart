import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../data/providers/students_provider.dart';
import '../widgets/student_card.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredStudents = ref.watch(filteredStudentsProvider(_searchQuery));
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estudiantes'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(studentsListProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiantes...',
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
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (filteredStudents.isEmpty) {
                  return _buildEmptyState(context, _searchQuery.isNotEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(studentsListProvider);
                  },
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return StudentCard(

                        key: ValueKey('student_${student.id}_$index'),
                        student: student,
                        onTap: () {
                          context.push('/student-profile/${student.id}');
                        },
                      );
                    },

                    cacheExtent: 500,
                  ),
                );
              },
              loading: () => _buildLoadingState(context),
              error: (error, stackTrace) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const Gap(16),
          Text('Cargando estudiantes...', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const Gap(16),
            Text(
              'Error al cargar estudiantes',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(studentsListProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              isSearching
                  ? 'No se encontraron estudiantes'
                  : 'No tienes estudiantes aún',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              isSearching
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Los estudiantes aparecerán aquí cuando reserven clases contigo',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const Gap(24),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/professor-home');
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Publicar Horario'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
