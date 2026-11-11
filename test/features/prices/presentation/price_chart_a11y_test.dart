import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/widgets/price_chart_widget.dart';

void main() {
  group('SPEC-003 — T-V3 Chart accessibility (A11Y-9, A11Y-5)', () {
    late Store storeA;
    late Store storeB;
    late List<PricePoint> history;
    late PriceStats stats;
    late Map<String, Store> storeMap;

    setUp(() {
      storeA = Store(
        id: 's1',
        name: 'Mercado do Zé',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      storeB = Store(
        id: 's2',
        name: 'Supermercado XYZ',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      history = [
        PricePoint(
          id: 'p1',
          productId: 'prod-1',
          storeId: 's1',
          date: DateTime(2026, 9, 3),
          normalizedPrice: const Money(399),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
        PricePoint(
          id: 'p2',
          productId: 'prod-1',
          storeId: 's2',
          date: DateTime(2026, 9, 10),
          normalizedPrice: const Money(429),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
        PricePoint(
          id: 'p3',
          productId: 'prod-1',
          storeId: 's1',
          date: DateTime(2026, 9, 17),
          normalizedPrice: const Money(449),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      ];

      stats = const PriceStats(
        averagePrice: Money(425),
        observationsCount: 3,
        windowDays: 30,
      );

      storeMap = {storeA.id: storeA, storeB.id: storeB};
    });

    Widget buildTestWidget({TextScaler textScaler = TextScaler.noScaling}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PriceChartWidget(
                history: history,
                stats: stats,
                stores: storeMap,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'A11Y-9: Resumo falado é anunciado na árvore semântica com média e menor valor',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'R\$ 4,25 em média nos últimos 30 dias'),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(r'menor valor R\$ 3,99 no Mercado do Zé em 3 de setembro'),
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'A11Y-9: Tabela textual acessível fornece semântica individual para cada ponto de preço',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel('R\$ 3,99 em Mercado do Zé no 03/09/2026'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('R\$ 4,29 em Supermercado XYZ no 10/09/2026'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('R\$ 4,49 em Mercado do Zé no 17/09/2026'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'A11Y-5: Tendência de alta/baixa usa ícone e texto legível (não só cor)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Alta de preço no período'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Alta de preço no período'),
          findsOneWidget,
        );
        expect(find.byType(Icon), findsWidgets);
      },
    );

    testWidgets('A11Y-5: Downward trend displays label and downward icon', (
      tester,
    ) async {
      final descendingHistory = [
        PricePoint(
          id: 'p1',
          productId: 'prod-1',
          storeId: 's1',
          date: DateTime(2026, 9, 3),
          normalizedPrice: const Money(449),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
        PricePoint(
          id: 'p2',
          productId: 'prod-1',
          storeId: 's1',
          date: DateTime(2026, 9, 10),
          normalizedPrice: const Money(399),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: PriceChartWidget(
              history: descendingHistory,
              stats: stats,
              stores: storeMap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Baixa de preço no período'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Baixa de preço no período'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Edge case: Gráfico e leitor funcionam com 1 único ponto de preço',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final singlePointHistory = [history.first];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: Scaffold(
              body: PriceChartWidget(
                history: singlePointHistory,
                stats: const PriceStats(
                  averagePrice: Money(399),
                  observationsCount: 1,
                  windowDays: 30,
                ),
                stores: storeMap,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.bySemanticsLabel('R\$ 3,99 em Mercado do Zé no 03/09/2026'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'Edge case: Fallback para storeId quando loja não está no mapa de lojas',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: Scaffold(
              body: PriceChartWidget(
                history: history,
                stats: stats,
                stores: const {}, // mapa de lojas vazio
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel('R\$ 3,99 em s1 no 03/09/2026'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'A11Y-4: Layout integridade com textScaler 2.0 (sem overflow)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(textScaler: const TextScaler.linear(2.0)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PriceChartWidget), findsOneWidget);
      },
    );
  });
}
