// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardSummary)
final dashboardSummaryProvider = DashboardSummaryFamily._();

final class DashboardSummaryProvider
    extends $AsyncNotifierProvider<DashboardSummary, MonthSummary?> {
  DashboardSummaryProvider._({
    required DashboardSummaryFamily super.from,
    required YearMonth super.argument,
  }) : super(
         retry: null,
         name: r'dashboardSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dashboardSummaryHash();

  @override
  String toString() {
    return r'dashboardSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DashboardSummary create() => DashboardSummary();

  @override
  bool operator ==(Object other) {
    return other is DashboardSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dashboardSummaryHash() => r'b62676f3446b4ddf7d67a4ce8d418c1245c978a6';

final class DashboardSummaryFamily extends $Family
    with
        $ClassFamilyOverride<
          DashboardSummary,
          AsyncValue<MonthSummary?>,
          MonthSummary?,
          FutureOr<MonthSummary?>,
          YearMonth
        > {
  DashboardSummaryFamily._()
    : super(
        retry: null,
        name: r'dashboardSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DashboardSummaryProvider call(YearMonth month) =>
      DashboardSummaryProvider._(argument: month, from: this);

  @override
  String toString() => r'dashboardSummaryProvider';
}

abstract class _$DashboardSummary extends $AsyncNotifier<MonthSummary?> {
  late final _$args = ref.$arg as YearMonth;
  YearMonth get month => _$args;

  FutureOr<MonthSummary?> build(YearMonth month);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MonthSummary?>, MonthSummary?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MonthSummary?>, MonthSummary?>,
              AsyncValue<MonthSummary?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
