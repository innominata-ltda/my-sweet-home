// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/widgets/price_chart_widget.dart';

// ── helpers ─────────────────────────────────────────────────────────────────

Store _makeStore(String id, String name) => Store(
  id: id,
  name: name,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

PricePoint _makePoint({
  required String id,
  required String storeId,
  required DateTime date,
  required int centsPerUnit,
}) => PricePoint(
  id: id,
  productId: 'prod-1',
  storeId: storeId,
  date: date,
  normalizedPrice: Money(centsPerUnit),
  unit: Unit.kg,
  source: PricePointSource.purchase,
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  // ── fixture compartilhado ─────────────────────────────────────────────────

  final storeA = _makeStore('s1', 'Mercado do Zé');
  final storeB = _makeStore('s2', 'Supermercado XYZ');

  final history = [
    _makePoint(
      id: 'p1',
      storeId: 's1',
      date: DateTime(2026, 9, 3),
      centsPerUnit: 399,
    ),
    _makePoint(
      id: 'p2',
      storeId: 's2',
      date: DateTime(2026, 9, 10),
      centsPerUnit: 429,
    ),
    _makePoint(
      id: 'p3',
      storeId: 's1',
      date: DateTime(2026, 9, 17),
      centsPerUnit: 449,
    ),
  ];

  final stats = const PriceStats(
    averagePrice: Money(425),
    observationsCount: 3,
    windowDays: 30,
  );

  final storeMap = {storeA.id: storeA, storeB.id: storeB};

  // ── A11Y-9: spoken label ─────────────────────────────────────────────────

  testWidgets(
    'A11Y-9 - Semantics label describes average, lowest price, store, and date',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PriceChartWidget(history: history, stats: stats, stores: storeMap),
        ),
      );
      await tester.pumpAndSettle();

      // Lowest price is p1 (R$3.99) at Mercado do Ze on September 3.
      // Chart semantics label must contain average and lowest price.
      final semanticsHandle = tester.ensureSemantics();

      // bySemanticsLabel(RegExp) verifies a node with this label pattern exists
      // - covering requirement A11Y-9 (spoken alternative of chart).
      expect(find.bySemanticsLabel(RegExp(r'R\$ 4,25')), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp(r'R\$ 3,99.*Mercado do Zé')),
        findsWidgets,
      );

      semanticsHandle.dispose();
    },
  );

  // ── A11Y-9: accessible textual table ─────────────────────────────────────

  testWidgets('A11Y-9 - Textual table lists each point with individual label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(PriceChartWidget(history: history, stats: stats, stores: storeMap)),
    );
    await tester.pumpAndSettle();

    final semanticsHandle = tester.ensureSemantics();

    // Semantic node must exist for each point mentioning price and
    // o nome do mercado (formato: "{price} em {store} no {date}").
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'R\$ 3,99 em Mercado do Zé')),
      ),
      isNotNull,
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'R\$ 4,29 em Supermercado XYZ')),
      ),
      isNotNull,
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'R\$ 4,49 em Mercado do Zé')),
      ),
      isNotNull,
    );

    semanticsHandle.dispose();
  });

  // ── A11Y-5: trend uses icon + text, never color alone ────────────────────

  testWidgets('A11Y-5 - Upward badge displays icon + text (not color alone)', (
    tester,
  ) async {
    // Last points: 3.99 -> 4.29 -> 4.49 (upward).
    await tester.pumpWidget(
      _wrap(PriceChartWidget(history: history, stats: stats, stores: storeMap)),
    );
    await tester.pumpAndSettle();

    // Must contain readable price increase text.
    expect(find.text('Alta de preço no período'), findsOneWidget);

    // Must contain an Icon (never just a colored Container).
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('A11Y-5 - Downward badge displays icon + text when price drops', (
    tester,
  ) async {
    final historyFalling = [
      _makePoint(
        id: 'p1',
        storeId: 's1',
        date: DateTime(2026, 9, 3),
        centsPerUnit: 499,
      ),
      _makePoint(
        id: 'p2',
        storeId: 's2',
        date: DateTime(2026, 9, 10),
        centsPerUnit: 449,
      ),
      _makePoint(
        id: 'p3',
        storeId: 's1',
        date: DateTime(2026, 9, 17),
        centsPerUnit: 399,
      ),
    ];
    final statsFalling = const PriceStats(
      averagePrice: Money(449),
      observationsCount: 3,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: historyFalling,
          stats: statsFalling,
          stores: storeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baixa de preço no período'), findsOneWidget);
    expect(find.byType(Icon), findsWidgets);
  });

  // ── A11Y-5: badge absent when price does not change ──────────────────────

  testWidgets('A11Y-5 - Badge absent when series has only 1 point', (
    tester,
  ) async {
    final singlePoint = [
      _makePoint(
        id: 'p1',
        storeId: 's1',
        date: DateTime(2026, 9, 3),
        centsPerUnit: 429,
      ),
    ];
    final singleStats = const PriceStats(
      averagePrice: Money(429),
      observationsCount: 1,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: singlePoint,
          stats: singleStats,
          stores: storeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alta de preço no período'), findsNothing);
    expect(find.text('Baixa de preço no período'), findsNothing);
  });

  // ── Chart renders without error with minimal data ─────────────────────

  testWidgets('Renders without error with single price point', (tester) async {
    final singlePoint = [
      _makePoint(
        id: 'p1',
        storeId: 's1',
        date: DateTime(2026, 9, 3),
        centsPerUnit: 429,
      ),
    ];
    final singleStats = const PriceStats(
      averagePrice: Money(429),
      observationsCount: 1,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: singlePoint,
          stats: singleStats,
          stores: storeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PriceChartWidget), findsOneWidget);
  });

  // ── Unknown store: fallback to storeId ───────────────────────────

  testWidgets('Displays storeId when Store does not exist in map', (
    tester,
  ) async {
    final orphanHistory = [
      _makePoint(
        id: 'p1',
        storeId: 'desconhecido',
        date: DateTime(2026, 9, 3),
        centsPerUnit: 399,
      ),
    ];
    final orphanStats = const PriceStats(
      averagePrice: Money(399),
      observationsCount: 1,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: orphanHistory,
          stats: orphanStats,
          stores: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fallback is raw storeId.
    expect(find.text('desconhecido'), findsWidgets);
  });

  // ── Empty history ────────────────────────────────────────────────────────

  testWidgets('Renders without error with empty history', (tester) async {
    const emptyStats = PriceStats(
      averagePrice: Money(0),
      observationsCount: 0,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: const [],
          stats: emptyStats,
          stores: storeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PriceChartWidget), findsOneWidget);
  });

  // ── Points on same date ───────────────────────────────────────────────────

  testWidgets('Renders without error with multiple points on same date', (
    tester,
  ) async {
    final sameDateHistory = [
      _makePoint(
        id: 'p1',
        storeId: 's1',
        date: DateTime(2026, 9, 3, 10, 0),
        centsPerUnit: 399,
      ),
      _makePoint(
        id: 'p2',
        storeId: 's2',
        date: DateTime(2026, 9, 3, 10, 0),
        centsPerUnit: 429,
      ),
    ];
    final sameDateStats = const PriceStats(
      averagePrice: Money(414),
      observationsCount: 2,
      windowDays: 30,
    );

    await tester.pumpWidget(
      _wrap(
        PriceChartWidget(
          history: sameDateHistory,
          stats: sameDateStats,
          stores: storeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PriceChartWidget), findsOneWidget);
  });

  // ── Golden: chart visual with normal history ───────────────────────

  testWidgets('Golden - PriceChartWidget with 3 price points', (tester) async {
    await tester.pumpWidget(
      _wrap(PriceChartWidget(history: history, stats: stats, stores: storeMap)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PriceChartWidget),
      matchesGoldenFile('price_chart_widget.png'),
    );
  });
}
