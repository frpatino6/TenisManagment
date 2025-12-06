import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/professor/presentation/screens/professor_home_screen.dart';
import '../../features/professor/presentation/screens/create_schedule_screen.dart';
import '../../features/professor/presentation/screens/manage_schedules_screen.dart';
import '../../features/professor/presentation/screens/pricing_config_screen.dart';
import '../../features/professor/presentation/screens/edit_profile_screen.dart';
import '../../features/professor/presentation/screens/students_list_screen.dart';
import '../../features/professor/presentation/screens/student_profile_screen.dart';
import '../../features/professor/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/booking/presentation/screens/book_class_screen.dart';
import '../../features/booking/presentation/screens/book_court_screen.dart';
import '../../features/booking/presentation/screens/professor_schedules_screen.dart';
import '../../features/booking/presentation/screens/confirm_booking_screen.dart';
import '../../features/booking/domain/models/schedule_model.dart';
import '../../features/student/presentation/screens/my_bookings_screen.dart';
import '../../features/student/presentation/screens/my_balance_screen.dart';
import '../../features/student/presentation/screens/request_service_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/tenant/presentation/screens/select_tenant_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/tenant_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasTenant = ref.watch(hasTenantProvider);
  final tenantState = ref.watch(tenantNotifierProvider);

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
      final isSelectingTenant = state.matchedLocation == '/select-tenant';
      final isBookCourt = state.matchedLocation == '/book-court';

      // If not authenticated, redirect to login (unless already there)
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and logging in, check tenant before redirecting
      if (isAuthenticated && isLoggingIn) {
        // Wait for tenant state to load
        if (tenantState.isLoading) {
          return null; // Wait for tenant to load
        }

        // If no tenant configured, redirect to tenant selection
        if (!hasTenant && !isSelectingTenant) {
          return '/select-tenant';
        }

        // If tenant is configured, redirect to home
        if (hasTenant) {
          return user.role == 'professor' ? '/professor-home' : '/home';
        }
      }

      // If authenticated and trying to access protected routes without tenant
      // BUT allow /book-court to stay even without tenant (it will show error message)
      if (isAuthenticated &&
          !isLoggingIn &&
          !isSelectingTenant &&
          !isBookCourt &&
          !hasTenant &&
          !tenantState.isLoading) {
        return '/select-tenant';
      }

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
        path: '/book-court',
        name: 'book-court',
        builder: (context, state) => const BookCourtScreen(),
      ),
      GoRoute(
        path: '/professor/:professorId/schedules',
        name: 'professor-schedules',
        builder: (context, state) {
          final professorId = state.pathParameters['professorId']!;
          final professorName = state.uri.queryParameters['name'] ?? 'Profesor';
          return ProfessorSchedulesScreen(
            professorId: professorId,
            professorName: professorName,
          );
        },
      ),
      GoRoute(
        path: '/confirm-booking',
        name: 'confirm-booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Error: No se proporcionaron datos')),
            );
          }
          return ConfirmBookingScreen(
            schedule: extra['schedule'] as ScheduleModel,
            professorId: extra['professorId'] as String,
            professorName: extra['professorName'] as String,
            tenantId: extra['tenantId'] as String,
            tenantName: extra['tenantName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/my-bookings',
        name: 'my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/my-balance',
        name: 'my-balance',
        builder: (context, state) => const MyBalanceScreen(),
      ),
      GoRoute(
        path: '/request-service',
        name: 'request-service',
        builder: (context, state) => const RequestServiceScreen(),
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
      GoRoute(
        path: '/pricing-config',
        name: 'pricing-config',
        builder: (context, state) => const PricingConfigScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/students-list',
        name: 'students-list',
        builder: (context, state) => const StudentsListScreen(),
      ),
      GoRoute(
        path: '/student-profile/:studentId',
        name: 'student-profile',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          return StudentProfileScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/analytics-dashboard',
        name: 'analytics-dashboard',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/theme-settings',
        name: 'theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/select-tenant',
        name: 'select-tenant',
        builder: (context, state) => const SelectTenantScreen(),
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
