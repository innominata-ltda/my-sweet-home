// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productAliases)
final productAliasesProvider = ProductAliasesFamily._();

final class ProductAliasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductAlias>>,
          List<ProductAlias>,
          FutureOr<List<ProductAlias>>
        >
    with
        $FutureModifier<List<ProductAlias>>,
        $FutureProvider<List<ProductAlias>> {
  ProductAliasesProvider._({
    required ProductAliasesFamily super.from,
    required ProductId super.argument,
  }) : super(
         retry: null,
         name: r'productAliasesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productAliasesHash();

  @override
  String toString() {
    return r'productAliasesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductAlias>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductAlias>> create(Ref ref) {
    final argument = this.argument as ProductId;
    return productAliases(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductAliasesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productAliasesHash() => r'060f167c2dba95f9fa00cc36d8f3622f81e76a5f';

final class ProductAliasesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductAlias>>, ProductId> {
  ProductAliasesFamily._()
    : super(
        retry: null,
        name: r'productAliasesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductAliasesProvider call(ProductId id) =>
      ProductAliasesProvider._(argument: id, from: this);

  @override
  String toString() => r'productAliasesProvider';
}

@ProviderFor(productDetail)
final productDetailProvider = ProductDetailFamily._();

final class ProductDetailProvider
    extends
        $FunctionalProvider<AsyncValue<Product?>, Product?, FutureOr<Product?>>
    with $FutureModifier<Product?>, $FutureProvider<Product?> {
  ProductDetailProvider._({
    required ProductDetailFamily super.from,
    required ProductId super.argument,
  }) : super(
         retry: null,
         name: r'productDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productDetailHash();

  @override
  String toString() {
    return r'productDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product?> create(Ref ref) {
    final argument = this.argument as ProductId;
    return productDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productDetailHash() => r'cca6efa40568cb7d1203bd967b326f8e41746ddd';

final class ProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product?>, ProductId> {
  ProductDetailFamily._()
    : super(
        retry: null,
        name: r'productDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductDetailProvider call(ProductId id) =>
      ProductDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'productDetailProvider';
}

@ProviderFor(ProductAliasController)
final productAliasControllerProvider = ProductAliasControllerProvider._();

final class ProductAliasControllerProvider
    extends $AsyncNotifierProvider<ProductAliasController, void> {
  ProductAliasControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productAliasControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productAliasControllerHash();

  @$internal
  @override
  ProductAliasController create() => ProductAliasController();
}

String _$productAliasControllerHash() =>
    r'1c890048e8b0d74cc2a6ef935eae7a1adee4f5ec';

abstract class _$ProductAliasController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
