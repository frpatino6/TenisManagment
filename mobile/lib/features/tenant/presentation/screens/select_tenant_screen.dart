import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/services/tenant_service.dart' as tenant_domain;
import '../../domain/models/tenant_model.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';

/// Screen for selecting a tenant (center)
///
/// Allows users to:
/// - View list of available tenants
/// - Search by code/slug
/// - Select a tenant to set as active
/// - Mark tenants as favorites
class SelectTenantScreen extends ConsumerStatefulWidget {
  const SelectTenantScreen({super.key});

  @override
  ConsumerState<SelectTenantScreen> createState() => _SelectTenantScreenState();
}

class _SelectTenantScreenState extends ConsumerState<SelectTenantScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TenantModel> _allTenants = [];
  List<TenantModel> _filteredTenants = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(tenant_domain.tenantDomainServiceProvider);
      // First try to get user's tenants, if empty, get all available
      var tenants = await service.getMyTenants();
      if (tenants.isEmpty) {
        // If user has no tenants, get all available tenants
        tenants = await service.getAvailableTenants();
      }

      setState(() {
        _allTenants = tenants;
        _filteredTenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar centros: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterTenants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTenants = _allTenants;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredTenants = _allTenants
            .where(
              (tenant) =>
                  tenant.name.toLowerCase().contains(query.toLowerCase()) ||
                  tenant.slug.toLowerCase().contains(query.toLowerCase()) ||
                  tenant.id.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _selectTenant(TenantModel tenant) async {
    if (!tenant.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este centro no está activo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(tenantNotifierProvider.notifier).setTenant(tenant.id);

      if (mounted) {
        // Navigate to home based on user role
        final user = ref.read(authStateProvider).value;
        if (user != null) {
          final route = user.role == 'professor' ? '/professor-home' : '/home';
          context.go(route);
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar centro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavoriteTenant(TenantModel tenant) async {
    try {
      final isFavorite = ref
          .read(preferencesNotifierProvider)
          .when(
            data: (preferences) =>
                preferences.favoriteTenants.any((t) => t.id == tenant.id),
            loading: () => false,
            error: (error, stackTrace) => false,
          );

      if (isFavorite) {
        await ref
            .read(preferencesNotifierProvider.notifier)
            .removeFavoriteTenant(tenant.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Centro eliminado de favoritos'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await ref
            .read(preferencesNotifierProvider.notifier)
            .addFavoriteTenant(tenant.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Centro agregado a favoritos'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchByCode(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un código'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(tenant_domain.tenantDomainServiceProvider);
      final tenant = await service.searchTenantByCode(code.trim());

      if (tenant != null) {
        await _selectTenant(tenant);
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Centro no encontrado con ese código'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al buscar centro: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTenantId = ref.watch(currentTenantIdProvider);
    final favoriteTenants = ref.watch(favoriteTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Centro'),
        actions: [
          if (currentTenantId != null)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Centro seleccionado',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ya tienes un centro seleccionado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterTenants('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _filterTenants,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ingresar código del centro',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: _searchByCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _searchByCode(_searchController.text),
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTenants,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _filteredTenants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching
                              ? Icons.search_off
                              : Icons.business_center,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'No se encontraron centros'
                              : 'No hay centros disponibles',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching
                              ? 'Intenta con otro término de búsqueda'
                              : 'Contacta al administrador para más información',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTenants.length,
                    itemBuilder: (context, index) {
                      final tenant = _filteredTenants[index];
                      final isSelected = currentTenantId == tenant.id;
                      final isFavorite = favoriteTenants.any(
                        (t) => t.id == tenant.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 2,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: tenant.logo != null
                                ? ClipOval(
                                    child: Image.network(
                                      tenant.logo!,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.business,
                                              color: Colors.white,
                                            );
                                          },
                                    ),
                                  )
                                : const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                  ),
                          ),
                          title: Text(
                            tenant.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código: ${tenant.slug}'),
                              if (!tenant.isActive)
                                const Text(
                                  'Inactivo',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite button
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                                onPressed: () => _toggleFavoriteTenant(tenant),
                                tooltip: isFavorite
                                    ? 'Eliminar de favoritos'
                                    : 'Agregar a favoritos',
                              ),
                              // Selection indicator
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              else
                                const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => _selectTenant(tenant),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
