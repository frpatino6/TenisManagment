// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentService)
const paymentServiceProvider = PaymentServiceProvider._();

final class PaymentServiceProvider
    extends $FunctionalProvider<PaymentService, PaymentService, PaymentService>
    with $Provider<PaymentService> {
  const PaymentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentServiceHash();

  @$internal
  @override
  $ProviderElement<PaymentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaymentService create(Ref ref) {
    return paymentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentService>(value),
    );
  }
}

String _$paymentServiceHash() => r'e7c36b959921562fad4961fbe41a8f0eb9fb92c4';

@ProviderFor(PaymentController)
const paymentControllerProvider = PaymentControllerProvider._();

final class PaymentControllerProvider
    extends $AsyncNotifierProvider<PaymentController, void> {
  const PaymentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentControllerHash();

  @$internal
  @override
  PaymentController create() => PaymentController();
}

String _$paymentControllerHash() => r'906a53bea9a8ba31e8a710aae3d894da25ec4c9f';

abstract class _$PaymentController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
