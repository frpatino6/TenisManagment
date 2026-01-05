import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthLoadingNotifier', () {
    test('should initialize with false', () {
      final container = ProviderContainer();
      final state = container.read(authLoadingProvider);

      expect(state, isFalse);
    });

    test('should set loading to true', () {
      final container = ProviderContainer();
      final notifier = container.read(authLoadingProvider.notifier);
      
      notifier.setLoading(true);
      
      final state = container.read(authLoadingProvider);
      expect(state, isTrue);
    });

    test('should set loading to false', () {
      final container = ProviderContainer();
      final notifier = container.read(authLoadingProvider.notifier);
      
      notifier.setLoading(true);
      notifier.setLoading(false);
      
      final state = container.read(authLoadingProvider);
      expect(state, isFalse);
    });
  });

  group('AuthErrorNotifier', () {
    test('should initialize with null', () {
      final container = ProviderContainer();
      final state = container.read(authErrorProvider);

      expect(state, isNull);
    });

    test('should set error message', () {
      final container = ProviderContainer();
      final notifier = container.read(authErrorProvider.notifier);
      
      notifier.setError('Error de autenticación');
      
      final state = container.read(authErrorProvider);
      expect(state, equals('Error de autenticación'));
    });

    test('should clear error', () {
      final container = ProviderContainer();
      final notifier = container.read(authErrorProvider.notifier);
      
      notifier.setError('Error de autenticación');
      notifier.clearError();
      
      final state = container.read(authErrorProvider);
      expect(state, isNull);
    });

    test('should set error to null', () {
      final container = ProviderContainer();
      final notifier = container.read(authErrorProvider.notifier);
      
      notifier.setError('Error de autenticación');
      notifier.setError(null);
      
      final state = container.read(authErrorProvider);
      expect(state, isNull);
    });
  });
}

