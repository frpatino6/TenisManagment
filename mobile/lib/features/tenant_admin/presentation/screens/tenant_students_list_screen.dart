import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/models/tenant_student_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantStudentsListScreen extends ConsumerStatefulWidget {
  const TenantStudentsListScreen({super.key});

  @override
  ConsumerState<TenantStudentsListScreen> createState() =>
      _TenantStudentsListScreenState();
}

class _TenantStudentsListScreenState
    extends ConsumerState<TenantStudentsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize search controller if there is an existing search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(studentSearchProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(tenantStudentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes')),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: studentsAsync.when(
              data: (data) {
                final students = data.students;
                final pagination = data.pagination;

                if (students.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron estudiantes'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Mostrando ${students.length} de ${pagination.total} estudiantes',
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            'Página ${pagination.page} / ${pagination.pages}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return _buildStudentCard(context, students[index]);
                        },
                      ),
                    ),
                    _buildPaginationActions(context, pagination),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => AppErrorWidget.fromError(
                error,
                onRetry: () => ref.invalidate(tenantStudentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(studentSearchProvider.notifier).set("");
                    ref.read(studentPageProvider.notifier).setPage(1);
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          // Debounce could be added here, but for now simple set
          ref.read(studentSearchProvider.notifier).set(value);
          ref.read(studentPageProvider.notifier).setPage(1);
          setState(() {}); // Update suffix icon visibility
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, TenantStudentModel student) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.email),
            const Gap(4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: student.balance >= 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Balance: ${CurrencyUtils.format(student.balance)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: student.balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  student.membershipType.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/tenant-admin-home/students/${student.id}');
        },
      ),
    );
  }

  Widget _buildPaginationActions(
    BuildContext context,
    StudentPagination pagination,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: pagination.page > 1
                ? () => ref
                      .read(studentPageProvider.notifier)
                      .setPage(pagination.page - 1)
                : null,
          ),
          const Gap(16),
          Text('${pagination.page} / ${pagination.pages}'),
          const Gap(16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: pagination.page < pagination.pages
                ? () => ref
                      .read(studentPageProvider.notifier)
                      .setPage(pagination.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
