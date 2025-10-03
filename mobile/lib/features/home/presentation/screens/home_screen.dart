import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/recent_activity_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
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
                'Error al cargar el usuario',
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
                onPressed: () => ref.invalidate(authStateProvider),
                child: const Text('Reintentar'),
              ),
            ],
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
        // App Bar personalizado
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
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      Gap(12),
                      Text('Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined),
                      Gap(12),
                      Text('Tema'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      Gap(12),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Contenido principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de perfil del usuario
                UserProfileCard(user: user)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0),

                const Gap(24),
                Text(
                      'Actividad Reciente',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 800.ms)
                    .slideX(begin: -0.2, end: 0),

                const Gap(16),

                RecentActivityList(user: user)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 1000.ms)
                    .slideY(begin: 0.2, end: 0),

                const Gap(24),

                // Versión de la aplicación
                FutureBuilder<PackageInfo?>(
                      future: _getPackageInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cargando versión...',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasData) {
                          final packageInfo = snapshot.data!;
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    packageInfo.appName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'v${packageInfo.version}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Build ${packageInfo.buildNumber}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Error cargando versión',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 1200.ms)
                    .slideY(begin: 0.2, end: 0),

                const Gap(24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'profile':
        break;
      case 'theme':
        context.push('/theme-settings');
        break;
      case 'logout':
        _handleLogout(context, ref);
        break;
    }
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

  Future<PackageInfo?> _getPackageInfo() async {
    try {
      if (kIsWeb) {
        // Para web, retornamos información hardcodeada ya que PackageInfo no funciona bien en web
        return PackageInfo(
          appName: 'Tennis Management',
          packageName: 'com.tennis.management',
          version: '1.3.0',
          buildNumber: '14',
          buildSignature: '',
          installerStore: '',
        );
      } else {
        // Para móvil, usamos PackageInfo.fromPlatform()
        return await PackageInfo.fromPlatform();
      }
    } catch (e) {
      // Si hay error, retornamos información por defecto
      return PackageInfo(
        appName: 'Tennis Management',
        packageName: 'com.tennis.management',
        version: '1.3.0',
        buildNumber: '14',
        buildSignature: '',
        installerStore: '',
      );
    }
  }
}
