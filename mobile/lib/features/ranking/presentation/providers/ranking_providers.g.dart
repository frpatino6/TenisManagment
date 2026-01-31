// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rankingRepository)
const rankingRepositoryProvider = RankingRepositoryProvider._();

final class RankingRepositoryProvider
    extends
        $FunctionalProvider<
          RankingRepository,
          RankingRepository,
          RankingRepository
        >
    with $Provider<RankingRepository> {
  const RankingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rankingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rankingRepositoryHash();

  @$internal
  @override
  $ProviderElement<RankingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RankingRepository create(Ref ref) {
    return rankingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RankingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RankingRepository>(value),
    );
  }
}

String _$rankingRepositoryHash() => r'a426b3bb74ce8447c2e03ceb16713a881c352b55';

@ProviderFor(getRankingsUseCase)
const getRankingsUseCaseProvider = GetRankingsUseCaseProvider._();

final class GetRankingsUseCaseProvider
    extends
        $FunctionalProvider<
          GetRankingsUseCase,
          GetRankingsUseCase,
          GetRankingsUseCase
        >
    with $Provider<GetRankingsUseCase> {
  const GetRankingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getRankingsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getRankingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetRankingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetRankingsUseCase create(Ref ref) {
    return getRankingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetRankingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetRankingsUseCase>(value),
    );
  }
}

String _$getRankingsUseCaseHash() =>
    r'39582d3d0049dd5e29fc45bd6a9d7a02163176eb';

@ProviderFor(EloRanking)
const eloRankingProvider = EloRankingProvider._();

final class EloRankingProvider
    extends $AsyncNotifierProvider<EloRanking, List<UserRanking>> {
  const EloRankingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eloRankingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eloRankingHash();

  @$internal
  @override
  EloRanking create() => EloRanking();
}

String _$eloRankingHash() => r'ace06fd8cbd8b2caf3790ebae741e823f23e6029';

abstract class _$EloRanking extends $AsyncNotifier<List<UserRanking>> {
  FutureOr<List<UserRanking>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<UserRanking>>, List<UserRanking>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserRanking>>, List<UserRanking>>,
              AsyncValue<List<UserRanking>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(RaceRanking)
const raceRankingProvider = RaceRankingProvider._();

final class RaceRankingProvider
    extends $AsyncNotifierProvider<RaceRanking, List<UserRanking>> {
  const RaceRankingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'raceRankingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$raceRankingHash();

  @$internal
  @override
  RaceRanking create() => RaceRanking();
}

String _$raceRankingHash() => r'e5e02d6215324b9f097be839a2d0f9729e7a714c';

abstract class _$RaceRanking extends $AsyncNotifier<List<UserRanking>> {
  FutureOr<List<UserRanking>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<UserRanking>>, List<UserRanking>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserRanking>>, List<UserRanking>>,
              AsyncValue<List<UserRanking>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(CurrentUserRanking)
const currentUserRankingProvider = CurrentUserRankingFamily._();

final class CurrentUserRankingProvider
    extends $NotifierProvider<CurrentUserRanking, UserRanking?> {
  const CurrentUserRankingProvider._({
    required CurrentUserRankingFamily super.from,
    required RankingType super.argument,
  }) : super(
         retry: null,
         name: r'currentUserRankingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentUserRankingHash();

  @override
  String toString() {
    return r'currentUserRankingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CurrentUserRanking create() => CurrentUserRanking();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRanking? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRanking?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserRankingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentUserRankingHash() =>
    r'fb027d1258987b8a2552e421975486e0f59de06c';

final class CurrentUserRankingFamily extends $Family
    with
        $ClassFamilyOverride<
          CurrentUserRanking,
          UserRanking?,
          UserRanking?,
          UserRanking?,
          RankingType
        > {
  const CurrentUserRankingFamily._()
    : super(
        retry: null,
        name: r'currentUserRankingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentUserRankingProvider call(RankingType type) =>
      CurrentUserRankingProvider._(argument: type, from: this);

  @override
  String toString() => r'currentUserRankingProvider';
}

abstract class _$CurrentUserRanking extends $Notifier<UserRanking?> {
  late final _$args = ref.$arg as RankingType;
  RankingType get type => _$args;

  UserRanking? build(RankingType type);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<UserRanking?, UserRanking?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserRanking?, UserRanking?>,
              UserRanking?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
