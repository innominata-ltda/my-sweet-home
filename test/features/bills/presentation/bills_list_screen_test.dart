import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_controller.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_screen.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_error_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

class FakeBillsListController extends ValueNotifier<BillsListState>
    implements BillsListController {
  FakeBillsListController(super.value);

  @override
  Future<void> load() async {}

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> dismissNotificationWarning() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildApp(
    BillsListController controller, {
    void Function(BillListItem)? onUnpayBill,
    String? highlightedBillId,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BillsListScreen(
        controller: controller,
        onCreateBill: () {},
        onPayBill: (_) {},
        onUnpayBill: onUnpayBill,
        onTapBill: (_) {},
        highlightedBillId: highlightedBillId,
      ),
    );
  }

  testWidgets('shows loading state', (tester) async {
    final controller = FakeBillsListController(BillsListLoading());
    await tester.pumpWidget(buildApp(controller));
    expect(find.byType(AppLoading), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    final controller = FakeBillsListController(
      BillsListSuccess(
        items: [],
        permissionState: PermissionState.granted,
        hasDismissedWarning: false,
      ),
    );
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(
      find.text('Cadastre suas contas fixas e nunca mais pague multa.'),
      findsOneWidget,
    );
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets(
    'shows all paid state and keeps paid bills visible and allows unpaying',
    (tester) async {
      BillListItem? unpayCalledWith;
      final billItem = BillListItem(
        bill: Bill(
          id: '1',
          title: 'Aluguel',
          categoryId: CategoryId('1'),
          dueDay: 5,
          recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
          isEstimated: false,
        ),
        payment: BillPayment(id: '1', billId: '1', dueOn: DateTime.now()),
        status: BillStatus.paid,
      );
      final controller = FakeBillsListController(
        BillsListSuccess(
          items: [billItem],
          permissionState: PermissionState.granted,
          hasDismissedWarning: false,
        ),
      );
      await tester.pumpWidget(
        buildApp(controller, onUnpayBill: (item) => unpayCalledWith = item),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nada a pagar este mês'), findsOneWidget);
      expect(find.text('Aluguel'), findsOneWidget);
      expect(find.text('Pago'), findsOneWidget);

      final unpayButton = find.byTooltip('Desmarcar pagamento de Aluguel');
      expect(unpayButton, findsOneWidget);

      await tester.tap(unpayButton);
      await tester.pumpAndSettle();

      expect(unpayCalledWith, equals(billItem));
    },
  );

  testWidgets('shows lack of permission state', (tester) async {
    final controller = FakeBillsListController(
      BillsListSuccess(
        items: [
          BillListItem(
            bill: Bill(
              id: '1',
              title: 'Luz',
              categoryId: CategoryId('1'),
              dueDay: 5,
              recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
              isEstimated: false,
            ),
            payment: BillPayment(id: '1', billId: '1', dueOn: DateTime.now()),
            status: BillStatus.pending,
          ),
        ],
        permissionState: PermissionState.denied,
        hasDismissedWarning: false,
      ),
    );
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Sem permissão, você não será avisado antes do vencimento e pode pagar multa.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error state', (tester) async {
    final controller = FakeBillsListController(
      BillsListError(StorageFailure(detail: 'err')),
    );
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('meets accessibility guidelines (A11Y)', (tester) async {
    final controller = FakeBillsListController(
      BillsListSuccess(
        items: [
          BillListItem(
            bill: Bill(
              id: '1',
              title: 'Luz',
              categoryId: CategoryId('1'),
              dueDay: 5,
              recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
              isEstimated: false,
            ),
            payment: BillPayment(
              id: '1',
              billId: '1',
              dueOn: DateTime(2026, 10, 5),
            ),
            status: BillStatus.pending,
          ),
        ],
        permissionState: PermissionState.granted,
        hasDismissedWarning: true,
      ),
    );

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets(
    'lista e botão "marcar como pago" são acessíveis (A11Y-2, A11Y-5, A11Y-6)',
    (tester) async {
      final controller = FakeBillsListController(
        BillsListSuccess(
          items: [
            BillListItem(
              bill: Bill(
                id: '1',
                title: 'Aluguel de março',
                categoryId: CategoryId('1'),
                dueDay: 5,
                recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
                isEstimated: false,
              ),
              payment: BillPayment(
                id: '1',
                billId: '1',
                dueOn: DateTime(2026, 3, 5),
              ),
              status: BillStatus.late,
            ),
            BillListItem(
              bill: Bill(
                id: '2',
                title: 'Luz',
                categoryId: CategoryId('1'),
                dueDay: 10,
                recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
                isEstimated: false,
              ),
              payment: BillPayment(
                id: '2',
                billId: '2',
                dueOn: DateTime(2026, 3, 10),
              ),
              status: BillStatus.pending,
            ),
          ],
          permissionState: PermissionState.granted,
          hasDismissedWarning: true,
        ),
      );

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildApp(controller));
      await tester.pumpAndSettle();

      // Verify status text is present for A11Y-5 ("Atrasado", "Pendente")
      expect(find.text('Atrasado'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);

      // Verify semantics of the button (A11Y-2, A11Y-5)
      final buttonFinder = find
          .widgetWithIcon(IconButton, AppIcons.money)
          .first;
      expect(
        tester.getSemantics(buttonFinder),
        matchesSemantics(
          isButton: true,
          tooltip: 'Marcar Aluguel de março como pago',
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      // Verify that the list tiles are ordered as they appear in the items list, which dictates semantic order (A11Y-6)
      final titles = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListTile),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(titles.contains('Aluguel de março'), isTrue);
      expect(titles.contains('Luz'), isTrue);
      expect(
        titles.indexOf('Aluguel de março') < titles.indexOf('Luz'),
        isTrue,
      );

      handle.dispose();
    },
  );

  testWidgets(
    'destaca visualmente o card da conta quando highlightedBillId é fornecido (T-B15 / RF-080, RF-082)',
    (tester) async {
      final bill1 = BillListItem(
        bill: Bill(
          id: 'bill-1',
          title: 'Internet Fibra',
          categoryId: CategoryId('cat-1'),
          dueDay: 15,
          recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
          isEstimated: false,
        ),
        payment: BillPayment(
          id: 'pay-1',
          billId: 'bill-1',
          dueOn: DateTime.utc(2026, 10, 15),
        ),
        status: BillStatus.pending,
      );

      final bill2 = BillListItem(
        bill: Bill(
          id: 'bill-2',
          title: 'Energia Elétrica',
          categoryId: CategoryId('cat-2'),
          dueDay: 20,
          recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
          isEstimated: false,
        ),
        payment: BillPayment(
          id: 'pay-2',
          billId: 'bill-2',
          dueOn: DateTime.utc(2026, 10, 20),
        ),
        status: BillStatus.pending,
      );

      final controller = FakeBillsListController(
        BillsListSuccess(
          items: [bill1, bill2],
          permissionState: PermissionState.granted,
          hasDismissedWarning: false,
        ),
      );

      // bill-1 is highlighted
      await tester.pumpWidget(
        buildApp(controller, highlightedBillId: 'bill-1'),
      );
      await tester.pumpAndSettle();

      // Highlighted item displays visual indicator 'Destaque'
      expect(find.text('Destaque'), findsOneWidget);

      // O material de bill-1 possui borda de destaque
      final materialFinder = find.byKey(const Key('bill_container_bill-1'));
      expect(materialFinder, findsOneWidget);

      final materialWidget = tester.widget<Material>(materialFinder);
      expect(materialWidget.shape, isA<RoundedRectangleBorder>());
      final border = (materialWidget.shape as RoundedRectangleBorder).side;
      expect(border.width, equals(2));

      // Inner ListTile has selected: true
      final tileFinder = find.byKey(const Key('bill_item_bill-1'));
      final tileWidget = tester.widget<ListTile>(tileFinder);
      expect(tileWidget.selected, isTrue);

      // bill-2 is not highlighted
      final unhighlightedMaterial = tester.widget<Material>(
        find.byKey(const Key('bill_container_bill-2')),
      );
      final unhighlightedBorder =
          (unhighlightedMaterial.shape as RoundedRectangleBorder).side;
      expect(unhighlightedBorder, equals(BorderSide.none));

      final unhighlightedTile = tester.widget<ListTile>(
        find.byKey(const Key('bill_item_bill-2')),
      );
      expect(unhighlightedTile.selected, isFalse);
    },
  );

  testWidgets(
    'visually highlights bill when opened via GoRouter with bill id in extra',
    (tester) async {
      final bill1 = BillListItem(
        bill: Bill(
          id: 'bill-target',
          title: 'Condomínio',
          categoryId: CategoryId('cat-1'),
          dueDay: 10,
          recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
          isEstimated: false,
        ),
        payment: BillPayment(
          id: 'pay-target',
          billId: 'bill-target',
          dueOn: DateTime.utc(2026, 10, 10),
        ),
        status: BillStatus.pending,
      );

      final controller = FakeBillsListController(
        BillsListSuccess(
          items: [bill1],
          permissionState: PermissionState.granted,
          hasDismissedWarning: false,
        ),
      );

      final router = GoRouter(
        initialLocation: '/init',
        routes: [
          GoRoute(
            path: '/init',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/contas', extra: 'bill-target'),
                child: const Text('Ir para contas'),
              ),
            ),
          ),
          GoRoute(
            path: '/contas',
            builder: (context, state) => Scaffold(
              body: BillsListScreen(
                controller: controller,
                onCreateBill: () {},
                onPayBill: (_) {},
                onTapBill: (_) {},
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Clicks button to navigate with extra
      await tester.tap(find.text('Ir para contas'));
      await tester.pumpAndSettle();

      expect(find.text('Condomínio'), findsOneWidget);
      expect(find.text('Destaque'), findsOneWidget);

      final tileWidget = tester.widget<ListTile>(
        find.byKey(const Key('bill_item_bill-target')),
      );
      expect(tileWidget.selected, isTrue);
    },
  );
}
