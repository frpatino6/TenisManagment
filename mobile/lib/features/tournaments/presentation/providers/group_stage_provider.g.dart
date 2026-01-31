// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_stage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider del repositorio de fase de grupos.

@ProviderFor(groupStageRepository)
const groupStageRepositoryProvider = GroupStageRepositoryProvider._();

/// Provider del repositorio de fase de grupos.

final class GroupStageRepositoryProvider
    extends
        $FunctionalProvider<
          GroupStageRepository,
          GroupStageRepository,
          GroupStageRepository
        >
    with $Provider<GroupStageRepository> {
  /// Provider del repositorio de fase de grupos.
  const GroupStageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupStageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupStageRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupStageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GroupStageRepository create(Ref ref) {
    return groupStageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupStageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupStageRepository>(value),
    );
  }
}

String _$groupStageRepositoryHash() =>
    r'9d9f3e7550e4cf97d158ade0f8b491a7c9d2bd5e';

/// Provider para obtener la fase de grupos de una categoría.

@ProviderFor(groupStage)
const groupStageProvider = GroupStageFamily._();

/// Provider para obtener la fase de grupos de una categoría.

final class GroupStageProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupStageModel?>,
          GroupStageModel?,
          FutureOr<GroupStageModel?>
        >
    with $FutureModifier<GroupStageModel?>, $FutureProvider<GroupStageModel?> {
  /// Provider para obtener la fase de grupos de una categoría.
  const GroupStageProvider._({
    required GroupStageFamily super.from,
    required ({String tournamentId, String categoryId}) super.argument,
  }) : super(
         retry: null,
         name: r'groupStageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupStageHash();

  @override
  String toString() {
    return r'groupStageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<GroupStageModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupStageModel?> create(Ref ref) {
    final argument =
        this.argument as ({String tournamentId, String categoryId});
    return groupStage(
      ref,
      tournamentId: argument.tournamentId,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupStageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupStageHash() => r'5b57793fbf668fe587ca3d0d37a2fe5d0da393ad';

/// Provider para obtener la fase de grupos de una categoría.

final class GroupStageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GroupStageModel?>,
          ({String tournamentId, String categoryId})
        > {
  const GroupStageFamily._()
    : super(
        retry: null,
        name: r'groupStageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para obtener la fase de grupos de una categoría.

  GroupStageProvider call({
    required String tournamentId,
    required String categoryId,
  }) => GroupStageProvider._(
    argument: (tournamentId: tournamentId, categoryId: categoryId),
    from: this,
  );

  @override
  String toString() => r'groupStageProvider';
}

/// Provider para generar grupos.

@ProviderFor(GroupStageGenerator)
const groupStageGeneratorProvider = GroupStageGeneratorProvider._();

/// Provider para generar grupos.
final class GroupStageGeneratorProvider
    extends $AsyncNotifierProvider<GroupStageGenerator, GroupStageModel?> {
  /// Provider para generar grupos.
  const GroupStageGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupStageGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupStageGeneratorHash();

  @$internal
  @override
  GroupStageGenerator create() => GroupStageGenerator();
}

String _$groupStageGeneratorHash() =>
    r'45a2f719b38d12dfd246e996af5a626945dbfbad';

/// Provider para generar grupos.

abstract class _$GroupStageGenerator extends $AsyncNotifier<GroupStageModel?> {
  FutureOr<GroupStageModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<GroupStageModel?>, GroupStageModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GroupStageModel?>, GroupStageModel?>,
              AsyncValue<GroupStageModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
