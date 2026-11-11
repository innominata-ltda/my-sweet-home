// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storeList)
final storeListProvider = StoreListProvider._();

final class StoreListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Store>>,
          List<Store>,
          FutureOr<List<Store>>
        >
    with $FutureModifier<List<Store>>, $FutureProvider<List<Store>> {
  StoreListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeListHash();

  @$internal
  @override
  $FutureProviderElement<List<Store>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Store>> create(Ref ref) {
    return storeList(ref);
  }
}

String _$storeListHash() => r'dd546b85ffda10f5861008e33d60119f121fefe8';
