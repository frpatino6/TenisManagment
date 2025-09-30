import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/professor/presentation/screens/professor_home_screen.dart';
import '../../features/professor/presentation/screens/create_schedule_screen.dart';
import '../../features/professor/presentation/screens/manage_schedules_screen.dart';
import '../../features/booking/presentation/screens/book_class_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authState.when(
        data: (user) => user,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      final isAuthenticated = user != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si está autenticado y trata de ir a login/register, redirigir según rol
      if (isAuthenticated && isLoggingIn) {
        return user.role == 'professor' ? '/professor-home' : '/home';
      }

      // Si no está autenticado y no está en login/register, redirigir a login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // No redirigir
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/professor-home',
        name: 'professor-home',
        builder: (context, state) => const ProfessorHomeScreen(),
      ),
      GoRoute(
        path: '/book-class',
        name: 'book-class',
        builder: (context, state) => const BookClassScreen(),
      ),
      GoRoute(
        path: '/create-schedule',
        name: 'create-schedule',
        builder: (context, state) => const CreateScheduleScreen(),
      ),
      GoRoute(
        path: '/manage-schedules',
        name: 'manage-schedules',
        builder: (context, state) => const ManageSchedulesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error 404',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
