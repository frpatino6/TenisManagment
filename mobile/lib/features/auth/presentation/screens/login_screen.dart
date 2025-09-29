import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../../../core/widgets/loading_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);

    // Mostrar loading si está autenticando
    if (authState.isLoading) {
      return const LoadingScreen(message: 'Verificando autenticación...');
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(40),

                // Logo y título
                _buildHeader(context),

                const Gap(48),

                // Formulario de login
                _buildLoginForm(context),

                const Gap(24),

                // Botón de login
                _buildLoginButton(context, isLoading),

                const Gap(16),

                // Divider
                _buildDivider(context),

                const Gap(16),

                // Botón de Google
                _buildGoogleButton(context, isLoading),

                const Gap(24),

                // Enlaces
                _buildLinks(context),

                const Gap(24),

                // Mostrar error si existe
                if (error != null) _buildErrorWidget(context, error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.sports_tennis,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),

        const Gap(24),

        // Título
        Text(
              'Bienvenido',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),

        const Gap(8),

        // Subtítulo
        Text(
              'Inicia sesión en tu cuenta',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      children: [
        // Campo de email
        CustomTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Ingresa tu email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 600.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        // Campo de contraseña
        CustomTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 800.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        // Recordar contraseña
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                'Recordar contraseña',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implementar recuperación de contraseña
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Función de recuperación de contraseña próximamente',
                    ),
                  ),
                );
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, bool isLoading) {
    return CustomButton(
          text: 'Iniciar Sesión',
          onPressed: isLoading ? null : _handleEmailLogin,
          isLoading: isLoading,
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'o',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 1400.ms);
  }

  Widget _buildGoogleButton(BuildContext context, bool isLoading) {
    return OutlinedButton.icon(
          onPressed: isLoading ? null : _handleGoogleLogin,
          icon: Image.asset(
            'assets/images/google_logo.png',
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.login,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes una cuenta? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Regístrate'),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 1800.ms);
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(authErrorProvider.notifier).clearError(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // El error se maneja automáticamente en el provider
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // El error se maneja automáticamente en el provider
    }
  }
}
