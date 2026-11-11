// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keep_screen_on_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(keepScreenOn)
final keepScreenOnProvider = KeepScreenOnProvider._();

final class KeepScreenOnProvider
    extends
        $FunctionalProvider<
          KeepScreenOnPort,
          KeepScreenOnPort,
          KeepScreenOnPort
        >
    with $Provider<KeepScreenOnPort> {
  KeepScreenOnProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keepScreenOnProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keepScreenOnHash();

  @$internal
  @override
  $ProviderElement<KeepScreenOnPort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeepScreenOnPort create(Ref ref) {
    return keepScreenOn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeepScreenOnPort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeepScreenOnPort>(value),
    );
  }
}

String _$keepScreenOnHash() => r'cfba7590304bac7737bc3efb1e7a39e195957f1f';
