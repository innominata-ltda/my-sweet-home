import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/global_search_repository.dart';

class GlobalSearchState {
  final String query;
  final bool isLoading;
  final GlobalSearchResults results;
  final Failure? failure;

  const GlobalSearchState({
    required this.query,
    required this.isLoading,
    required this.results,
    this.failure,
  });

  factory GlobalSearchState.initial() => const GlobalSearchState(
    query: '',
    isLoading: false,
    results: GlobalSearchResults(items: []),
  );

  GlobalSearchState copyWith({
    String? query,
    bool? isLoading,
    GlobalSearchResults? results,
    Failure? failure,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      failure: failure,
    );
  }
}

class GlobalSearchController extends ValueNotifier<GlobalSearchState> {
  GlobalSearchController(
    this._repository, {
    this.debounce = const Duration(milliseconds: 250),
  }) : super(GlobalSearchState.initial());

  final GlobalSearchRepository _repository;
  final Duration debounce;

  Timer? _debounceTimer;
  int _generation = 0;

  void search(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _generation++;
      value = value.copyWith(
        query: query,
        isLoading: false,
        results: const GlobalSearchResults(items: []),
      );
      return;
    }

    // Atualiza a query digitada imediatamente para reatividade do campo de busca.
    value = value.copyWith(query: query);

    _debounceTimer = Timer(debounce, () async {
      final currentGen = ++_generation;
      value = value.copyWith(isLoading: true);

      final res = await _repository.search(trimmed);
      if (currentGen != _generation) {
        // Discard query response superseded by newer generation (RN-430).
        return;
      }

      if (res.isOk) {
        value = value.copyWith(isLoading: false, results: res.valueOrNull!);
      } else {
        value = value.copyWith(isLoading: false, failure: res.failureOrNull);
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    _generation++;
    value = GlobalSearchState.initial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
