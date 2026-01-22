import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/version_widget.dart';
import '../../../../core/widgets/update_check_wrapper.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/favorite_professor_card.dart';
import '../widgets/favorite_tenant_card.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = ref.watch(authLoadingProvider);

    return UpdateCheckWrapper(
      child: Scaffold(
        body: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Usuario no encontrado'));
            }

            return _buildHomeContent(context, user, isLoading, ref);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const Gap(16),
                Text(
                  'Error al cargar el usuario.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Gap(8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authNotifierProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    user,
    bool isLoading,
    WidgetRef ref,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Hola, ${user.name.split(' ').first}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.sports_tennis, size: 40, color: Colors.white),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              onPressed: () => _showProfileMenu(context, ref),
              icon: Icon(
                Icons.account_circle_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserProfileCard(user: user)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),

                const Gap(24),

                // Favorites section
                _buildFavoritesSection(context, ref)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 150.ms)
                    .slideY(begin: 0.1, end: 0),

                const Gap(24),

                Text(
                      'Acciones Rápidas',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideX(begin: -0.1, end: 0),

                const Gap(16),

                QuickActionsGrid(user: user)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const Gap(24),

                Center(
                      child: VersionBadge(
                        showBuildNumber: true,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 600.ms)
                    .slideY(begin: 0.1, end: 0),

                const Gap(24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Cambiar Centro'),
              onTap: () {
                Navigator.pop(context);
                context.push('/select-tenant');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Tema'),
              onTap: () {
                Navigator.pop(context);
                context.push('/theme-settings');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, ref);
              },
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
        }
      }
    }
  }

  Widget _buildFavoritesSection(BuildContext context, WidgetRef ref) {
    final favoriteProfessors = ref.watch(favoriteProfessorsProvider);
    final favoriteTenants = ref.watch(favoriteTenantsProvider);

    // Show empty state if no favorites
    if (favoriteProfessors.isEmpty && favoriteTenants.isEmpty) {
      return _buildEmptyFavoritesState(context, ref);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const Gap(8),
            Text(
              'Favoritos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Gap(16),
        // Favorite Professor
        if (favoriteProfessors.isNotEmpty)
          FavoriteProfessorCard(professor: favoriteProfessors.first),
        // Favorite Tenant
        if (favoriteTenants.isNotEmpty)
          FavoriteTenantCard(tenant: favoriteTenants.first),
      ],
    );
  }

  Widget _buildEmptyFavoritesState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const Gap(16),
          Text(
            '¡Bienvenido!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            'Agrega profesores y centros favoritos para acceder rápidamente a tus reservas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/select-tenant');
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Explorar centros'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/book-class');
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar profesores'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
