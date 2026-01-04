import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'student';
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // Prellenar campos para pruebas
    _nameController.text = 'cliente1';
    _emailController.text = 'cliente1@gmail.com';
    _phoneController.text = '3000000000';
    _passwordController.text = 's4ntiago';
    _confirmPasswordController.text = 's4ntiago';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(16),

                _buildHeader(context),

                const Gap(32),

                _buildForm(context),

                const Gap(24),

                _buildRegisterButton(context, isLoading),

                const Gap(16),

                _buildDivider(context),

                const Gap(16),

                _buildGoogleButton(context, isLoading),

                const Gap(24),

                _buildLinks(context),

                const Gap(24),

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
        Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.sports_tennis,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOut)
            .fadeIn(duration: 400.ms),

        const Gap(16),

        Text(
              'Crear Cuenta',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),

        const Gap(8),

        Text(
              'Únete a nuestra comunidad de tenis',
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

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
              controller: _nameController,
              label: 'Nombre completo',
              hint: 'Ingresa tu nombre completo',
              prefixIcon: Icons.person_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                if (value.length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 600.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

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
            .fadeIn(duration: 400.ms, delay: 800.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        CustomTextField(
              controller: _phoneController,
              label: 'Teléfono',
              hint: 'Ingresa tu número de teléfono',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu teléfono';
                }
                if (value.length < 10) {
                  return 'El teléfono debe tener al menos 10 dígitos';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1000.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        _buildRoleSelector(context),

        const Gap(16),

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
            .fadeIn(duration: 400.ms, delay: 1200.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              hint: 'Confirma tu contraseña',
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1400.ms)
            .slideX(begin: -0.2, end: 0),

        const Gap(16),

        _buildTermsCheckbox(context),
      ],
    );
  }

  Widget _buildRoleSelector(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de cuenta',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const Gap(8),
            RadioGroup<String>(
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRole = 'student';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedRole == 'student'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(value: 'student'),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estudiante'),
                                  Text(
                                    'Aprende tenis',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRole = 'professor';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedRole == 'professor'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(value: 'professor'),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Profesor'),
                                  Text(
                                    'Enseña tenis',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1100.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'términos y condiciones',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'política de privacidad',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 1600.ms);
  }

  Widget _buildRegisterButton(BuildContext context, bool isLoading) {
    return CustomButton(
          text: 'Crear Cuenta',
          onPressed: _acceptTerms ? (isLoading ? null : _handleRegister) : null,
          isLoading: isLoading,
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1800.ms)
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    ).animate().fadeIn(duration: 400.ms, delay: 2000.ms);
  }

  Widget _buildGoogleButton(BuildContext context, bool isLoading) {
    return OutlinedButton.icon(
          onPressed: isLoading ? null : _handleGoogleRegister,
          icon: Icon(
            Icons.login,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 2200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Inicia sesión'),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 2400.ms);
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .registerWithEmail(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      // Error handled by provider
    }
  }

  Future<void> _handleGoogleRegister() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      // Error handled by provider
    }
  }
}
