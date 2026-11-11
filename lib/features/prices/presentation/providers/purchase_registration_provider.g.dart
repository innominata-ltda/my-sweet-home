// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_registration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PurchaseRegistration)
final purchaseRegistrationProvider = PurchaseRegistrationProvider._();

final class PurchaseRegistrationProvider
    extends $NotifierProvider<PurchaseRegistration, PurchaseRegistrationState> {
  PurchaseRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseRegistrationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseRegistrationHash();

  @$internal
  @override
  PurchaseRegistration create() => PurchaseRegistration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseRegistrationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseRegistrationState>(value),
    );
  }
}

String _$purchaseRegistrationHash() =>
    r'd6eebc971bf695e6c52790fed39d5a26f22654e3';

abstract class _$PurchaseRegistration
    extends $Notifier<PurchaseRegistrationState> {
  PurchaseRegistrationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PurchaseRegistrationState, PurchaseRegistrationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PurchaseRegistrationState, PurchaseRegistrationState>,
              PurchaseRegistrationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
