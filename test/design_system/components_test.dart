import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_confirm_sheet.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_list_tile.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/design_system/components/app_undo_snack_bar.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? lightTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('T-14 — Componentes base do Design System', () {
    // ── AppButton ────────────────────────────────────────────────────────────
    group('AppButton', () {
      testWidgets('variante primary renderiza e onPressed funciona', (
        tester,
      ) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            AppButton.primary(label: 'Salvar', onPressed: () => pressed = true),
          ),
        );

        expect(find.text('Salvar'), findsOneWidget);
        await tester.tap(find.text('Salvar'));
        expect(pressed, isTrue);
      });

      testWidgets('variante secondary renderiza e onPressed funciona', (
        tester,
      ) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            AppButton.secondary(
              label: 'Cancelar',
              onPressed: () => pressed = true,
            ),
          ),
        );

        expect(find.text('Cancelar'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        expect(pressed, isTrue);
      });

      testWidgets('variante text renderiza e onPressed funciona', (
        tester,
      ) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            AppButton.text(label: 'Pular', onPressed: () => pressed = true),
          ),
        );

        expect(find.text('Pular'), findsOneWidget);
        await tester.tap(find.text('Pular'));
        expect(pressed, isTrue);
      });

      testWidgets('variante danger renderiza e onPressed funciona', (
        tester,
      ) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            AppButton.danger(label: 'Excluir', onPressed: () => pressed = true),
          ),
        );

        expect(find.text('Excluir'), findsOneWidget);
        await tester.tap(find.text('Excluir'));
        expect(pressed, isTrue);
      });

      testWidgets('loading state desabilita clique e exibe indicador', (
        tester,
      ) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            AppButton.primary(
              label: 'Carregando',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.byType(AppButton));
        expect(pressed, isFalse);
      });

      testWidgets('renders with icon and respects minimum 48dp touchTarget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            AppButton(
              label: 'Adicionar',
              icon: const Icon(AppIcons.add),
              onPressed: () {},
            ),
          ),
        );

        expect(find.byIcon(AppIcons.add), findsOneWidget);
        expect(find.text('Adicionar'), findsOneWidget);

        final size = tester.getSize(find.byType(AppButton));
        expect(size.height, greaterThanOrEqualTo(Spacing.touchTarget));
      });
    });

    // ── AppTextField ─────────────────────────────────────────────────────────
    group('AppTextField', () {
      testWidgets('exibe label e hint, onChanged funciona', (tester) async {
        String? changedText;
        await tester.pumpWidget(
          _wrap(
            AppTextField(
              label: 'Nome',
              hint: 'Digite seu nome',
              onChanged: (val) => changedText = val,
            ),
          ),
        );

        expect(find.text('Nome'), findsOneWidget);
        expect(find.text('Digite seu nome'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'John');
        expect(changedText, equals('John'));
      });

      testWidgets('exibe errorText quando informado', (tester) async {
        await tester.pumpWidget(
          _wrap(const AppTextField(label: 'Field', errorText: 'Required')),
        );

        expect(find.text('Required'), findsOneWidget);
      });
    });

    // ── AppMoneyField ────────────────────────────────────────────────────────
    group('AppMoneyField', () {
      testWidgets("aceita entrada '12,34' e converte para centavos (1234)", (
        tester,
      ) async {
        int? receivedCents;
        Money? receivedMoney;

        await tester.pumpWidget(
          _wrap(
            AppMoneyField(
              onChanged: (cents) => receivedCents = cents,
              onChangedMoney: (m) => receivedMoney = m,
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '12,34');
        expect(receivedCents, equals(1234));
        expect(receivedMoney, equals(const Money(1234)));
      });

      testWidgets("aceita entrada inteira '12' e converte para 1200 centavos", (
        tester,
      ) async {
        int? receivedCents;
        await tester.pumpWidget(
          _wrap(AppMoneyField(onChanged: (cents) => receivedCents = cents)),
        );

        await tester.enterText(find.byType(TextFormField), '12');
        expect(receivedCents, equals(1200));
      });

      testWidgets("accepts entry with period '12.34' and converts to cents", (
        tester,
      ) async {
        int? receivedCents;
        await tester.pumpWidget(
          _wrap(AppMoneyField(onChanged: (cents) => receivedCents = cents)),
        );

        await tester.enterText(find.byType(TextFormField), '12.34');
        expect(receivedCents, equals(1234));
      });

      testWidgets('inicializa com initialCents formatado', (tester) async {
        await tester.pumpWidget(_wrap(const AppMoneyField(initialCents: 5678)));

        expect(find.text('56,78'), findsOneWidget);
      });
    });

    // ── AppScaffold ──────────────────────────────────────────────────────────
    group('AppScaffold', () {
      testWidgets('renders title, body, and action without exception', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: AppScaffold(
              title: 'Minha Tela',
              actions: [
                IconButton(
                  icon: const Icon(AppIcons.settings),
                  onPressed: () {},
                ),
              ],
              body: const Text('Body content'),
            ),
          ),
        );

        expect(find.text('Minha Tela'), findsOneWidget);
        expect(find.text('Body content'), findsOneWidget);
        expect(find.byIcon(AppIcons.settings), findsOneWidget);
      });
    });

    // ── AppCard ──────────────────────────────────────────────────────────────
    group('AppCard', () {
      testWidgets('renderiza child com padding e onTap funciona', (
        tester,
      ) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            AppCard(
              onTap: () => tapped = true,
              child: const Text('Card content'),
            ),
          ),
        );

        expect(find.text('Card content'), findsOneWidget);
        await tester.tap(find.text('Card content'));
        expect(tapped, isTrue);
      });
    });

    // ── AppListTile ──────────────────────────────────────────────────────────
    group('AppListTile', () {
      testWidgets(
        'renderiza leading, title, subtitle, trailing e onTap funciona',
        (tester) async {
          var tapped = false;
          await tester.pumpWidget(
            _wrap(
              AppListTile(
                leading: const Icon(AppIcons.shopping),
                title: const Text('Arroz'),
                subtitle: const Text('5 kg'),
                trailing: const Icon(AppIcons.check),
                onTap: () => tapped = true,
              ),
            ),
          );

          expect(find.text('Arroz'), findsOneWidget);
          expect(find.text('5 kg'), findsOneWidget);
          expect(find.byIcon(AppIcons.shopping), findsOneWidget);
          expect(find.byIcon(AppIcons.check), findsOneWidget);

          await tester.tap(find.text('Arroz'));
          expect(tapped, isTrue);
        },
      );
    });

    // ── AppEmptyState ────────────────────────────────────────────────────────
    group('AppEmptyState', () {
      testWidgets('displays icon, text, and button, and onAction works', (
        tester,
      ) async {
        var actionClicked = false;
        await tester.pumpWidget(
          _wrap(
            AppEmptyState(
              icon: AppIcons.shopping,
              title: 'Your list is empty',
              description:
                  'Add items so you do not forget anything at the market.',
              actionLabel: 'Criar item',
              onAction: () => actionClicked = true,
            ),
          ),
        );

        expect(find.byIcon(AppIcons.shopping), findsOneWidget);
        expect(find.text('Your list is empty'), findsOneWidget);
        expect(
          find.text('Add items so you do not forget anything at the market.'),
          findsOneWidget,
        );
        expect(find.text('Criar item'), findsOneWidget);

        await tester.tap(find.text('Criar item'));
        expect(actionClicked, isTrue);
      });
    });

    // ── AppLoading ───────────────────────────────────────────────────────────
    group('AppLoading', () {
      testWidgets(
        'renders skeleton list without exception and without spinner',
        (tester) async {
          await tester.pumpWidget(_wrap(const AppLoading(itemCount: 3)));

          expect(find.byType(AppLoading), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );

      testWidgets(
        'renders AppLoading.box and AppLoading.card without exception',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              const Column(
                children: [
                  AppLoading.box(width: 100, height: 20),
                  AppLoading.card(height: 60),
                ],
              ),
            ),
          );

          expect(find.byType(AppLoading), findsNWidgets(2));
        },
      );

      testWidgets(
        'renderiza AppLoading(size: 20) e AppLoading.spinner exibindo CircularProgressIndicator',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              const Column(
                children: [AppLoading(size: 20), AppLoading.spinner(size: 24)],
              ),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
        },
      );
    });

    // ── AppConfirmSheet ──────────────────────────────────────────────────────
    group('AppConfirmSheet', () {
      testWidgets('displays title, message, and buttons work', (tester) async {
        var confirmed = false;
        var cancelled = false;

        await tester.pumpWidget(
          _wrap(
            AppConfirmSheet(
              title: 'Excluir registro?',
              message: 'This action can be undone in the next 5 seconds.',
              confirmLabel: 'Sim, excluir',
              cancelLabel: 'No, keep',
              isDanger: true,
              onConfirm: () => confirmed = true,
              onCancel: () => cancelled = true,
            ),
          ),
        );

        expect(find.text('Excluir registro?'), findsOneWidget);
        expect(
          find.text('This action can be undone in the next 5 seconds.'),
          findsOneWidget,
        );
        expect(find.text('Sim, excluir'), findsOneWidget);
        expect(find.text('No, keep'), findsOneWidget);

        await tester.tap(find.text('No, keep'));
        expect(cancelled, isTrue);
        expect(confirmed, isFalse);

        await tester.tap(find.text('Sim, excluir'));
        expect(confirmed, isTrue);
      });

      testWidgets('AppConfirmSheet.show abre bottom sheet e retorna resposta', (
        tester,
      ) async {
        bool? sheetResult;

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    sheetResult = await AppConfirmSheet.show(
                      context,
                      title: 'Confirmation',
                      message: 'Deseja prosseguir?',
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Confirmation'), findsOneWidget);
        expect(find.text('Deseja prosseguir?'), findsOneWidget);

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(sheetResult, isTrue);
      });
    });

    // ── AppUndoSnackBar ──────────────────────────────────────────────────────
    group('AppUndoSnackBar', () {
      testWidgets('displays message, undo action, and 5-second duration', (
        tester,
      ) async {
        var undone = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppUndoSnackBar.show(
                      context,
                      message: 'Item deleted',
                      onUndo: () => undone = true,
                    );
                  },
                  child: const Text('Excluir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        expect(find.text('Item deleted'), findsOneWidget);
        expect(find.text('Desfazer'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(const Duration(seconds: 5)));

        await tester.tap(find.text('Desfazer'));
        expect(undone, isTrue);
      });
    });
  });
}
