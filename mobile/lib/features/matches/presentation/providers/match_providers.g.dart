// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchRepository)
const matchRepositoryProvider = MatchRepositoryProvider._();

final class MatchRepositoryProvider
    extends
        $FunctionalProvider<MatchRepository, MatchRepository, MatchRepository>
    with $Provider<MatchRepository> {
  const MatchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchRepositoryHash();

  @$internal
  @override
  $ProviderElement<MatchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MatchRepository create(Ref ref) {
    return matchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchRepository>(value),
    );
  }
}

String _$matchRepositoryHash() => r'e8b580796f7ec55c81fb10774030a50c88cb62c5';

@ProviderFor(RecordMatchAction)
const recordMatchActionProvider = RecordMatchActionProvider._();

final class RecordMatchActionProvider
    extends $NotifierProvider<RecordMatchAction, AsyncValue<void>> {
  const RecordMatchActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordMatchActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordMatchActionHash();

  @$internal
  @override
  RecordMatchAction create() => RecordMatchAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$recordMatchActionHash() => r'aa17751a13f248b0c2969f0cfdca1a21c7e3708e';

abstract class _$RecordMatchAction extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
