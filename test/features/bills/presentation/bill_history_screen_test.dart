import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/presentation/bill_history_controller.dart';
import 'package:my_sweet_home/features/bills/presentation/bill_history_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';

class FakeBillHistoryController extends ValueNotifier<BillHistoryState>
    implements BillHistoryController {
  FakeBillHistoryController(super.value) : billId = 'fake-id';

  @override
  final BillId billId;

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildApp(BillHistoryController controller) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BillHistoryScreen(controller: controller),
    );
  }

  testWidgets('shows loading state', (tester) async {
    final controller = FakeBillHistoryController(BillHistoryLoading());
    await tester.pumpWidget(buildApp(controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state', (tester) async {
    final controller = FakeBillHistoryController(
      BillHistoryError(const StorageFailure(detail: 'err')),
    );
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();
    expect(find.text('Falha ao carregar o histórico.'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    final bill = Bill(
      id: '1',
      title: 'Aluguel',
      categoryId: CategoryId('1'),
      dueDay: 5,
      recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
      isEstimated: false,
    );
    final controller = FakeBillHistoryController(
      BillHistorySuccess(bill: bill, payments: []),
    );
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum pagamento registrado para esta conta.'),
      findsOneWidget,
    );
  });

  testWidgets('shows payments history', (tester) async {
    final bill = Bill(
      id: '1',
      title: 'Aluguel',
      categoryId: CategoryId('1'),
      dueDay: 5,
      recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
      isEstimated: false,
    );
    final controller = FakeBillHistoryController(
      BillHistorySuccess(
        bill: bill,
        payments: [
          BillPayment(
            id: 'p1',
            billId: '1',
            dueOn: DateTime(2026, 3, 5),
            paidOn: DateTime(2026, 3, 6),
            paidAmount: const Money(120000),
          ),
          BillPayment(id: 'p2', billId: '1', dueOn: DateTime(2026, 4, 5)),
        ],
      ),
    );

    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('Vencimento: 05/03/2026'), findsOneWidget);
    expect(find.text('Pago em: 06/03/2026'), findsOneWidget);

    expect(find.text('Vencimento: 05/04/2026'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });
}
