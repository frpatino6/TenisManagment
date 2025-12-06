import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/tenant_provider.dart';

/// Screen for selecting a tenant (center)
///
/// This is a placeholder screen that will be fully implemented in TEN-93
/// For now, it just shows a message and allows basic tenant selection
class SelectTenantScreen extends ConsumerWidget {
  const SelectTenantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantState = ref.watch(tenantNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Centro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Selecciona un Centro',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para continuar, necesitas seleccionar el centro donde deseas operar.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (tenantState.isLoading)
                const CircularProgressIndicator()
              else if (tenantState.hasError)
                Text(
                  'Error: ${tenantState.error}',
                  style: const TextStyle(color: Colors.red),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement full tenant selection in TEN-93
                    // For now, this is just a placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La selección de centros se implementará en TEN-93',
                        ),
                      ),
                    );
                  },
                  child: const Text('Seleccionar Centro'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
