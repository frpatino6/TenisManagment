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
import '../../features/student/presentation/screens/recent_activity_screen.dart';
import '../../features/student/presentation/screens/request_service_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/tenant/presentation/screens/select_tenant_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_admin_home_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_config_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_professors_list_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_invite_professor_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_courts_list_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_create_court_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_edit_court_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_bookings_list_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_booking_details_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_booking_stats_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_booking_calendar_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_students_list_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_student_details_screen.dart';
import '../../features/tenant_admin/presentation/screens/tenant_professor_details_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/tenant_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifierState = ref.watch(authNotifierProvider);
  final authState = ref.watch(authStateProvider);
  final tenantState = ref.watch(tenantNotifierProvider);
  final hasTenant = ref.watch(hasTenantProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      if (currentPath == '/book-court' ||
          currentPath.startsWith('/book-court')) {
        return null;
      }
      if (currentPath == '/manage-schedules' ||
          currentPath.startsWith('/manage-schedules')) {
        return null;
      }
      // Don't redirect from select-tenant screen when user is selecting/changing tenant
      if (currentPath == '/select-tenant') {
        return null;
      }

      final userFromNotifier = authNotifierState.value;
      final userFromStream = authState.when(
        data: (user) => user,
        loading: () => null,
        error: (_, _) => null,
      );
      final user = userFromNotifier ?? userFromStream;
      final isAuthenticated = user != null;
      final isLoggingIn = currentPath == '/login' || currentPath == '/register';
      final isSelectingTenant = currentPath == '/select-tenant';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated) {
        // CRITICAL: When user is on login/register screen after authentication,
        // wait for tenant to finish loading before making any navigation decisions.
        // This prevents briefly showing the select-tenant screen.
        if (isLoggingIn) {
          // If tenant is still loading, stay on login screen (it will show loading state)
          if (tenantState.isLoading) {
            return null;
          }

          // Tenant finished loading, now decide where to go
          if (user.role == 'tenant_admin') {
            return '/tenant-admin-home';
          }
          // Professors should NEVER see select-tenant screen, go directly to professor-home
          if (user.role == 'professor') {
            return '/professor-home';
          }
          // For students: only show select-tenant if they don't have a favorite tenant
          if (user.role == 'student') {
            if (hasTenant) {
              return '/home';
            } else {
              return '/select-tenant';
            }
          }
          // Default fallback (should not reach here)
          return '/home';
        }

        // For other screens (not login/register), handle tenant state
        // If tenant is loading, don't redirect yet (wait for it to complete)
        if (tenantState.isLoading) {
          return null;
        }

        // tenant_admin should NEVER see select-tenant screen
        if (user.role == 'tenant_admin') {
          if (currentPath != '/tenant-admin-home' &&
              !currentPath.startsWith('/tenant-')) {
            return '/tenant-admin-home';
          }
          return null;
        }

        // Professors should NEVER see select-tenant screen
        if (user.role == 'professor') {
          if (currentPath == '/select-tenant') {
            return '/professor-home';
          }
          return null;
        }

        // For students: only redirect to select-tenant if they don't have a favorite tenant
        if (user.role == 'student' && !hasTenant && !isSelectingTenant) {
          return '/select-tenant';
        }
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
        path: '/tenant-admin-home',
        name: 'tenant-admin-home',
        builder: (context, state) => const TenantAdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'config',
            name: 'tenant-admin-config',
            builder: (context, state) => const TenantConfigScreen(),
          ),
          GoRoute(
            path: 'professors',
            name: 'tenant-admin-professors',
            builder: (context, state) => const TenantProfessorsListScreen(),
            routes: [
              GoRoute(
                path: 'invite',
                name: 'tenant-admin-professors-invite',
                builder: (context, state) =>
                    const TenantInviteProfessorScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'tenant-admin-professor-details',
                builder: (context, state) {
                  final professorId = state.pathParameters['id']!;
                  return TenantProfessorDetailsScreen(professorId: professorId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'courts',
            name: 'tenant-admin-courts',
            builder: (context, state) => const TenantCourtsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'tenant-admin-courts-create',
                builder: (context, state) => const TenantCreateCourtScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'tenant-admin-courts-edit',
                builder: (context, state) {
                  final courtId = state.pathParameters['id']!;
                  return TenantEditCourtScreen(courtId: courtId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'bookings',
            name: 'tenant-admin-bookings',
            builder: (context, state) => const TenantBookingsListScreen(),
            routes: [
              GoRoute(
                path: 'stats',
                name: 'tenant-admin-booking-stats',
                builder: (context, state) => const TenantBookingStatsScreen(),
              ),
              GoRoute(
                path: 'calendar',
                name: 'tenant-admin-booking-calendar',
                builder: (context, state) =>
                    const TenantBookingCalendarScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'tenant-admin-booking-details',
                builder: (context, state) {
                  final bookingId = state.pathParameters['id']!;
                  return TenantBookingDetailsScreen(bookingId: bookingId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'students',
            name: 'tenant-admin-students',
            builder: (context, state) => const TenantStudentsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'tenant-admin-student-details',
                builder: (context, state) {
                  final studentId = state.pathParameters['id']!;
                  return TenantStudentDetailsScreen(studentId: studentId);
                },
              ),
            ],
          ),
        ],
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
        path: '/recent-activity',
        name: 'recent-activity',
        builder: (context, state) => const RecentActivityScreen(),
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
