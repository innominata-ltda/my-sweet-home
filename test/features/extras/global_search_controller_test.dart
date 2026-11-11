import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/global_search_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_controller.dart';

class _RecordingGlobalSearchRepository implements GlobalSearchRepository {
  final List<String> searchCalls = [];
  Future<Result<GlobalSearchResults, Failure>> Function(String query)? onSearch;

  @override
  Future<Result<GlobalSearchResults, Failure>> search(
    String query, {
    int limitPerType = 20,
  }) async {
    searchCalls.add(query);
    if (onSearch != null) {
      return onSearch!(query);
    }
    return const Ok(GlobalSearchResults(items: []));
  }
}

void main() {
  group('GlobalSearchController - Debounce and Generations (RN-430)', () {
    late _RecordingGlobalSearchRepository repository;
    late GlobalSearchController controller;

    setUp(() {
      repository = _RecordingGlobalSearchRepository();
      controller = GlobalSearchController(
        repository,
        debounce: const Duration(milliseconds: 250),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'CA-5.8: Digitação letra a letra a cada 100 ms dispara apenas 1 consulta após 250 ms de pausa',
      (tester) async {
        // Digita "a" em t=0ms
        controller.search('a');
        expect(controller.value.query, equals('a'));
        expect(repository.searchCalls, isEmpty);

        // Digita "ar" em t=100ms
        await tester.pump(const Duration(milliseconds: 100));
        controller.search('ar');
        expect(repository.searchCalls, isEmpty);

        // Digita "arr" em t=200ms
        await tester.pump(const Duration(milliseconds: 100));
        controller.search('arr');
        expect(repository.searchCalls, isEmpty);

        // Digita "arro" em t=300ms
        await tester.pump(const Duration(milliseconds: 100));
        controller.search('arro');
        expect(repository.searchCalls, isEmpty);

        // Digita "arroz" em t=400ms
        await tester.pump(const Duration(milliseconds: 100));
        controller.search('arroz');
        expect(repository.searchCalls, isEmpty);

        // 240 ms after "arroz" (t=640ms): should not have queried yet
        await tester.pump(const Duration(milliseconds: 240));
        expect(repository.searchCalls, isEmpty);

        // Another 20 ms (t=660ms, 260 ms after "arroz"): debounce fires exactly 1 time
        await tester.pump(const Duration(milliseconds: 20));
        expect(repository.searchCalls, equals(['arroz']));
        expect(controller.value.isLoading, isFalse);
      },
    );

    testWidgets(
      'RN-430: Resultados de consultas superadas por geração mais nova são descartados',
      (tester) async {
        final arrozCompleter =
            Completer<Result<GlobalSearchResults, Failure>>();
        final feijaoCompleter =
            Completer<Result<GlobalSearchResults, Failure>>();

        repository.onSearch = (query) {
          if (query == 'arroz') return arrozCompleter.future;
          if (query == 'feijao') return feijaoCompleter.future;
          return Future.value(const Ok(GlobalSearchResults(items: [])));
        };

        // Dispara busca por "arroz"
        controller.search('arroz');
        await tester.pump(const Duration(milliseconds: 260));
        expect(repository.searchCalls, equals(['arroz']));
        expect(controller.value.isLoading, isTrue);

        // User changes mind and types "feijao"
        controller.search('feijao');
        await tester.pump(const Duration(milliseconds: 260));
        expect(repository.searchCalls, equals(['arroz', 'feijao']));

        // A consulta lenta de "arroz" responde agora
        arrozCompleter.complete(
          const Ok(
            GlobalSearchResults(
              items: [
                GlobalSearchResult(
                  id: 'p-arroz',
                  title: 'Arroz Branco',
                  type: GlobalSearchResultType.product,
                  targetId: 'prod-1',
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        // "arroz" result must be DISCARDED because generation is obsolete
        expect(controller.value.results.items, isEmpty);
        expect(controller.value.isLoading, isTrue);

        // A consulta de "feijao" completa
        feijaoCompleter.complete(
          const Ok(
            GlobalSearchResults(
              items: [
                GlobalSearchResult(
                  id: 'p-feijao',
                  title: 'Feijão Preto',
                  type: GlobalSearchResultType.product,
                  targetId: 'prod-2',
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(controller.value.isLoading, isFalse);
        expect(controller.value.results.items.length, equals(1));
        expect(
          controller.value.results.items.first.title,
          equals('Feijão Preto'),
        );
      },
    );

    testWidgets('clear() cancela timer pendente e redefine o estado', (
      tester,
    ) async {
      controller.search('arroz');
      await tester.pump(const Duration(milliseconds: 100));

      controller.clear();
      expect(controller.value.query, isEmpty);
      expect(controller.value.results.items, isEmpty);

      // Advances remaining time of previous debounce
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.searchCalls, isEmpty);
    });

    testWidgets(
      'Busca por texto vazio reseta resultados imediatamente sem chamar repositório',
      (tester) async {
        controller.search('   ');
        await tester.pump(const Duration(milliseconds: 300));

        expect(repository.searchCalls, isEmpty);
        expect(controller.value.results.items, isEmpty);
        expect(controller.value.isLoading, isFalse);
      },
    );

    testWidgets('dispose() safely cancels pending timer without error', (
      tester,
    ) async {
      final localController = GlobalSearchController(
        repository,
        debounce: const Duration(milliseconds: 250),
      );
      localController.search('arroz');
      localController.dispose();

      // Advance time; no error should occur and search should not trigger
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.searchCalls, isEmpty);
    });
  });
}
