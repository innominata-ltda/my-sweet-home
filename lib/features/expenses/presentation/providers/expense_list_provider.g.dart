// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseList)
final expenseListProvider = ExpenseListFamily._();

final class ExpenseListProvider
    extends $AsyncNotifierProvider<ExpenseList, List<Expense>> {
  ExpenseListProvider._({
    required ExpenseListFamily super.from,
    required YearMonth super.argument,
  }) : super(
         retry: null,
         name: r'expenseListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseListHash();

  @override
  String toString() {
    return r'expenseListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExpenseList create() => ExpenseList();

  @override
  bool operator ==(Object other) {
    return other is ExpenseListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseListHash() => r'3af3bbc0cea7c5262ff38901d029a88d1805dfd0';

final class ExpenseListFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseList,
          AsyncValue<List<Expense>>,
          List<Expense>,
          FutureOr<List<Expense>>,
          YearMonth
        > {
  ExpenseListFamily._()
    : super(
        retry: null,
        name: r'expenseListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpenseListProvider call(YearMonth month) =>
      ExpenseListProvider._(argument: month, from: this);

  @override
  String toString() => r'expenseListProvider';
}

abstract class _$ExpenseList extends $AsyncNotifier<List<Expense>> {
  late final _$args = ref.$arg as YearMonth;
  YearMonth get month => _$args;

  FutureOr<List<Expense>> build(YearMonth month);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Expense>>, List<Expense>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Expense>>, List<Expense>>,
              AsyncValue<List<Expense>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
