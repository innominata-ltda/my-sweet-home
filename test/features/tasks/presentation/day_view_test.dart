import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';
import 'package:my_sweet_home/features/tasks/presentation/day_view.dart';

void main() {
  const localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  const supportedLocales = [Locale('pt', 'BR'), Locale('en', 'US')];

  testWidgets('DayView exibe contas a vencer no dia', (tester) async {
    final today = DateTime.utc(2026, 10, 15);
    final bill = CalendarBill(
      id: 'bill-1',
      title: 'Internet Fibra',
      amountCents: 12000,
      dueOn: today,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Scaffold(
          body: DayView(date: today, bills: [bill]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Contas a vencer hoje (1):'), findsOneWidget);
    expect(find.textContaining('Internet Fibra'), findsOneWidget);
    expect(find.textContaining('R\$ 120.00'), findsOneWidget);
    expect(find.textContaining('(Pendente)'), findsOneWidget);
  });

  testWidgets('DayView invoca onTapBill ao tocar em conta do dia', (
    tester,
  ) async {
    final today = DateTime.utc(2026, 10, 15);
    final bill = CalendarBill(
      id: 'bill-1',
      title: 'Energia Elétrica',
      amountCents: 25000,
      dueOn: today,
    );

    CalendarBill? tappedBill;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Scaffold(
          body: DayView(
            date: today,
            bills: [bill],
            onTapBill: (b) => tappedBill = b,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final billFinder = find.byKey(const Key('calendar_bill_bill-1'));
    expect(billFinder, findsOneWidget);

    await tester.tap(billFinder);
    await tester.pumpAndSettle();

    expect(tappedBill, isNotNull);
    expect(tappedBill!.id, equals('bill-1'));
    expect(tappedBill!.title, equals('Energia Elétrica'));
  });

  testWidgets(
    'DayView navigates to /contas with bill id in extra on tap without callback',
    (tester) async {
      final today = DateTime.utc(2026, 10, 15);
      final bill = CalendarBill(
        id: 'bill-42',
        title: 'Aluguel',
        amountCents: 150000,
        dueOn: today,
      );

      String? receivedExtra;

      final router = GoRouter(
        initialLocation: '/dia',
        routes: [
          GoRoute(
            path: '/dia',
            builder: (context, state) => Scaffold(
              body: DayView(date: today, bills: [bill]),
            ),
          ),
          GoRoute(
            path: '/contas',
            builder: (context, state) {
              receivedExtra = state.extra as String?;
              return Scaffold(body: Text('Tela de Contas: $receivedExtra'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final billFinder = find.byKey(const Key('calendar_bill_bill-42'));
      expect(billFinder, findsOneWidget);

      await tester.tap(billFinder);
      await tester.pumpAndSettle();

      expect(find.text('Tela de Contas: bill-42'), findsOneWidget);
      expect(receivedExtra, equals('bill-42'));
    },
  );
}
