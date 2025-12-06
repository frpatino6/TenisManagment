import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_preferences_model.dart';
import '../../domain/services/preferences_service.dart';

/// Notifier for managing user preferences
class PreferencesNotifier extends Notifier<AsyncValue<UserPreferencesModel>> {
  PreferencesService get _service => ref.read(preferencesServiceProvider);

  @override
  AsyncValue<UserPreferencesModel> build() {
    // Load preferences on initialization
    Future.microtask(() => loadPreferences());
    return const AsyncValue.loading();
  }

  /// Load preferences from backend
  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();
    try {
      final preferences = await _service.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Add professor to favorites
  Future<void> addFavoriteProfessor(String professorId) async {
    try {
      await _service.addFavoriteProfessor(professorId);
      // Reload preferences
      await loadPreferences();
    } catch (e) {
      // Error is handled by state, but we can rethrow if needed
      rethrow;
    }
  }

  /// Remove professor from favorites
  Future<void> removeFavoriteProfessor(String professorId) async {
    try {
      await _service.removeFavoriteProfessor(professorId);
      // Reload preferences
      await loadPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Add tenant to favorites
  Future<void> addFavoriteTenant(String tenantId) async {
    try {
      await _service.addFavoriteTenant(tenantId);
      // Reload preferences
      await loadPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove tenant from favorites
  Future<void> removeFavoriteTenant(String tenantId) async {
    try {
      await _service.removeFavoriteTenant(tenantId);
      // Reload preferences
      await loadPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle professor favorite status
  Future<void> toggleFavoriteProfessor(String professorId) async {
    return state.when(
      data: (preferences) async {
        final isFavorite = preferences.favoriteProfessors.any(
          (p) => p.id == professorId,
        );
        if (isFavorite) {
          await removeFavoriteProfessor(professorId);
        } else {
          await addFavoriteProfessor(professorId);
        }
      },
      loading: () async {
        await loadPreferences();
      },
      error: (error, stackTrace) async {
        await loadPreferences();
      },
    );
  }

  /// Toggle tenant favorite status
  Future<void> toggleFavoriteTenant(String tenantId) async {
    return state.when(
      data: (preferences) async {
        final isFavorite = preferences.favoriteTenants.any(
          (t) => t.id == tenantId,
        );
        if (isFavorite) {
          await removeFavoriteTenant(tenantId);
        } else {
          await addFavoriteTenant(tenantId);
        }
      },
      loading: () async {
        await loadPreferences();
      },
      error: (error, stackTrace) async {
        await loadPreferences();
      },
    );
  }

  /// Check if professor is favorite
  bool isProfessorFavorite(String professorId) {
    return state.when(
      data: (preferences) =>
          preferences.favoriteProfessors.any((p) => p.id == professorId),
      loading: () => false,
      error: (error, stackTrace) => false,
    );
  }

  /// Check if tenant is favorite
  bool isTenantFavorite(String tenantId) {
    return state.when(
      data: (preferences) =>
          preferences.favoriteTenants.any((t) => t.id == tenantId),
      loading: () => false,
      error: (error, stackTrace) => false,
    );
  }

  /// Get favorite professor by ID
  FavoriteProfessor? getFavoriteProfessor(String professorId) {
    return state.when(
      data: (preferences) {
        try {
          return preferences.favoriteProfessors.firstWhere(
            (p) => p.id == professorId,
          );
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }

  /// Get favorite tenant by ID
  FavoriteTenant? getFavoriteTenant(String tenantId) {
    return state.when(
      data: (preferences) {
        try {
          return preferences.favoriteTenants.firstWhere(
            (t) => t.id == tenantId,
          );
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }
}

/// Provider for PreferencesNotifier
final preferencesNotifierProvider =
    NotifierProvider<PreferencesNotifier, AsyncValue<UserPreferencesModel>>(() {
      return PreferencesNotifier();
    });

/// Provider for current preferences (value only, no loading/error states)
final currentPreferencesProvider = Provider<UserPreferencesModel?>((ref) {
  return ref
      .watch(preferencesNotifierProvider)
      .when(
        data: (preferences) => preferences,
        loading: () => null,
        error: (error, stackTrace) => null,
      );
});

/// Provider for favorite professors list
final favoriteProfessorsProvider = Provider<List<FavoriteProfessor>>((ref) {
  final preferences = ref.watch(currentPreferencesProvider);
  return preferences?.favoriteProfessors ?? [];
});

/// Provider for favorite tenants list
final favoriteTenantsProvider = Provider<List<FavoriteTenant>>((ref) {
  final preferences = ref.watch(currentPreferencesProvider);
  return preferences?.favoriteTenants ?? [];
});
