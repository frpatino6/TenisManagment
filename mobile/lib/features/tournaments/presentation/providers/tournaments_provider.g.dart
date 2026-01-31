// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournaments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider del repositorio de torneos.

@ProviderFor(tournamentRepository)
const tournamentRepositoryProvider = TournamentRepositoryProvider._();

/// Provider del repositorio de torneos.

final class TournamentRepositoryProvider
    extends
        $FunctionalProvider<
          TournamentRepository,
          TournamentRepository,
          TournamentRepository
        >
    with $Provider<TournamentRepository> {
  /// Provider del repositorio de torneos.
  const TournamentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentRepositoryHash();

  @$internal
  @override
  $ProviderElement<TournamentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TournamentRepository create(Ref ref) {
    return tournamentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TournamentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TournamentRepository>(value),
    );
  }
}

String _$tournamentRepositoryHash() =>
    r'84bfb42488b92ca05e6906c041deb2a27680a200';

/// Provider para la lista de torneos.

@ProviderFor(Tournaments)
const tournamentsProvider = TournamentsProvider._();

/// Provider para la lista de torneos.
final class TournamentsProvider
    extends $AsyncNotifierProvider<Tournaments, List<TournamentModel>> {
  /// Provider para la lista de torneos.
  const TournamentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentsHash();

  @$internal
  @override
  Tournaments create() => Tournaments();
}

String _$tournamentsHash() => r'c0fa28da801227172691fa42cdbfd333f453d9fb';

/// Provider para la lista de torneos.

abstract class _$Tournaments extends $AsyncNotifier<List<TournamentModel>> {
  FutureOr<List<TournamentModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TournamentModel>>, List<TournamentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TournamentModel>>,
                List<TournamentModel>
              >,
              AsyncValue<List<TournamentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider para un torneo específico.

@ProviderFor(TournamentDetail)
const tournamentDetailProvider = TournamentDetailFamily._();

/// Provider para un torneo específico.
final class TournamentDetailProvider
    extends $AsyncNotifierProvider<TournamentDetail, TournamentModel> {
  /// Provider para un torneo específico.
  const TournamentDetailProvider._({
    required TournamentDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentDetailHash();

  @override
  String toString() {
    return r'tournamentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TournamentDetail create() => TournamentDetail();

  @override
  bool operator ==(Object other) {
    return other is TournamentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentDetailHash() => r'059f7e6ca6d862138268d4f0dfc7191d035236e4';

/// Provider para un torneo específico.

final class TournamentDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          TournamentDetail,
          AsyncValue<TournamentModel>,
          TournamentModel,
          FutureOr<TournamentModel>,
          String
        > {
  const TournamentDetailFamily._()
    : super(
        retry: null,
        name: r'tournamentDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para un torneo específico.

  TournamentDetailProvider call(String tournamentId) =>
      TournamentDetailProvider._(argument: tournamentId, from: this);

  @override
  String toString() => r'tournamentDetailProvider';
}

/// Provider para un torneo específico.

abstract class _$TournamentDetail extends $AsyncNotifier<TournamentModel> {
  late final _$args = ref.$arg as String;
  String get tournamentId => _$args;

  FutureOr<TournamentModel> build(String tournamentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<TournamentModel>, TournamentModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TournamentModel>, TournamentModel>,
              AsyncValue<TournamentModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider para el bracket de una categoría.

@ProviderFor(Bracket)
const bracketProvider = BracketFamily._();

/// Provider para el bracket de una categoría.
final class BracketProvider
    extends $AsyncNotifierProvider<Bracket, BracketModel?> {
  /// Provider para el bracket de una categoría.
  const BracketProvider._({
    required BracketFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'bracketProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bracketHash();

  @override
  String toString() {
    return r'bracketProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Bracket create() => Bracket();

  @override
  bool operator ==(Object other) {
    return other is BracketProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bracketHash() => r'f56f9d2ec30c1008a889f2021e0ac1ea68bbcd1e';

/// Provider para el bracket de una categoría.

final class BracketFamily extends $Family
    with
        $ClassFamilyOverride<
          Bracket,
          AsyncValue<BracketModel?>,
          BracketModel?,
          FutureOr<BracketModel?>,
          (String, String)
        > {
  const BracketFamily._()
    : super(
        retry: null,
        name: r'bracketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para el bracket de una categoría.

  BracketProvider call(String tournamentId, String categoryId) =>
      BracketProvider._(argument: (tournamentId, categoryId), from: this);

  @override
  String toString() => r'bracketProvider';
}

/// Provider para el bracket de una categoría.

abstract class _$Bracket extends $AsyncNotifier<BracketModel?> {
  late final _$args = ref.$arg as (String, String);
  String get tournamentId => _$args.$1;
  String get categoryId => _$args.$2;

  FutureOr<BracketModel?> build(String tournamentId, String categoryId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<AsyncValue<BracketModel?>, BracketModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BracketModel?>, BracketModel?>,
              AsyncValue<BracketModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
