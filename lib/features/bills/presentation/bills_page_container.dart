import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';

import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_controller.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_screen.dart';
import 'package:my_sweet_home/features/bills/presentation/bill_history_controller.dart';
import 'package:my_sweet_home/features/bills/presentation/bill_history_screen.dart';
import 'package:my_sweet_home/features/bills/presentation/create_bill_dialog.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/pay_bill_use_case.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';

class _FakeNotificationScheduler implements NotificationSchedulerPort {
  @override
  Future<Result<void, Failure>> cancel(String id) async => const Ok(null);

  @override
  Future<List<ScheduledNotification>> pending() async => [];
  @override
  Future<PermissionState> permission() async => PermissionState.granted;
  @override
  Future<Result<void, Failure>> rescheduleAllAfterBoot() async =>
      const Ok(null);
  @override
  Future<Result<void, Failure>> schedule(
    ScheduledNotification notification,
  ) async => const Ok(null);
}

class BillsPageContainer extends ConsumerStatefulWidget {
  const BillsPageContainer({super.key});

  @override
  ConsumerState<BillsPageContainer> createState() => _BillsPageContainerState();
}

class _BillsPageContainerState extends ConsumerState<BillsPageContainer> {
  late final BillsListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BillsListController(
      billRepository: ref.read(billRepositoryProvider),
      paymentRepository: ref.read(billPaymentRepositoryProvider),
      notificationScheduler: _FakeNotificationScheduler(),
      preferences: ref.read(billsPreferencesProvider),
      statusPolicy: DefaultBillStatusPolicy(),
      batteryWarningService: ref.read(batteryWarningServiceProvider),
      clock: ref.read(clockProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BillsListScreen(
      controller: _controller,
      onCreateBill: () async {
        final catRepo = ref.read(categoryRepositoryProvider);
        final catsResult = await catRepo.all();
        final categories = catsResult.isOk
            ? catsResult.valueOrNull!
            : <Category>[];
        if (!context.mounted) return;

        await showDialog<void>(
          context: context,
          builder: (ctx) => CreateBillDialog(
            categories: categories,
            onSave: (title, amountCents, dueDay, categoryId, [recurrence]) async {
              final repo = ref.read(billRepositoryProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final newBillResult = await repo.upsert(
                NewBill(
                  title: title,
                  categoryId: categoryId,
                  dueDay: dueDay,
                  recurrence:
                      recurrence ??
                      RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
                  amount: Money(amountCents),
                  isEstimated: false,
                ),
              );

              if (newBillResult is Ok<Bill, Failure>) {
                final bill = newBillResult.value;
                final paymentRepo = ref.read(billPaymentRepositoryProvider);
                final clock = ref.read(clockProvider);
                final now = clock.nowUtc();
                final today = DateTime.utc(now.year, now.month, now.day);
                final yearMonth = YearMonth.of(now);
                const dueDatePolicy = StandardDueDatePolicy();
                final thisMonthDue = dueDatePolicy.dueDateFor(
                  dueDay: bill.dueDay,
                  month: yearMonth,
                );

                // If current month due date already passed relative to today,
                // first occurrence is next month so it does not appear overdue.
                final firstMonth = thisMonthDue.isBefore(today)
                    ? yearMonth.next
                    : yearMonth;
                final firstDueOn = dueDatePolicy.dueDateFor(
                  dueDay: bill.dueDay,
                  month: firstMonth,
                );

                const deterministicIdGen = UuidV5DeterministicIdGenerator();
                final firstDueIso =
                    '${firstDueOn.year.toString().padLeft(4, '0')}-${firstDueOn.month.toString().padLeft(2, '0')}-${firstDueOn.day.toString().padLeft(2, '0')}';
                await paymentRepo.upsertOccurrences([
                  BillPayment(
                    id: deterministicIdGen.forOccurrence(bill.id, firstDueIso),
                    billId: bill.id,
                    dueOn: firstDueOn,
                  ),
                ]);

                // Also materialize future occurrences
                final materializer = BillMaterializer(
                  billRepo: repo,
                  paymentRepo: paymentRepo,
                  dueDatePolicy: dueDatePolicy,
                );
                await materializer.materializeUpTo(
                  now.add(const Duration(days: 60)),
                );

                await _controller.load();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Conta "$title" cadastrada com sucesso!'),
                  ),
                );
              } else if (newBillResult is Err<Bill, Failure>) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao cadastrar conta: ${userMessageFor(newBillResult.failure)}',
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
      onPayBill: (item) async {
        final messenger = ScaffoldMessenger.of(context);
        final amount = item.bill.amount ?? const Money(0);
        final useCase = DefaultPayBillUseCase(
          ref.read(billPaymentRepositoryProvider),
          ref.read(billRepositoryProvider),
          ref.read(expenseRepositoryProvider),
          _FakeNotificationScheduler(),
        );
        final res = await useCase(
          item.payment.id,
          amount: amount,
          paidOn: ref.read(clockProvider).nowUtc(),
        );
        if (res.isOk) {
          await _controller.load();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Conta "${item.bill.title}" marcada como paga!'),
            ),
          );
        }
      },
      onUnpayBill: (item) async {
        final messenger = ScaffoldMessenger.of(context);
        final useCase = DefaultUnpayBillUseCase(
          ref.read(billPaymentRepositoryProvider),
          ref.read(billRepositoryProvider),
          ref.read(expenseRepositoryProvider),
          const DefaultReminderPlanner(),
          _FakeNotificationScheduler(),
          ref.read(clockProvider),
        );
        final res = await useCase(item.payment.id);
        if (res.isOk) {
          await _controller.load();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Conta "${item.bill.title}" marcada como não paga!',
              ),
            ),
          );
        }
      },
      onPauseBill: (item) async {
        final messenger = ScaffoldMessenger.of(context);
        await _controller.pauseBill(item.bill.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Conta "${item.bill.title}" pausada com sucesso!'),
          ),
        );
      },
      onDeleteBill: (item) async {
        final messenger = ScaffoldMessenger.of(context);
        final res = await _controller.deleteBill(item.bill.id);
        if (!context.mounted) return;
        if (res.isOk) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Conta "${item.bill.title}" excluída com sucesso!'),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao excluir conta: ${res.failureOrNull?.toString() ?? ''}',
              ),
            ),
          );
        }
      },
      onTapBill: (item) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) {
              final historyController = BillHistoryController(
                billId: item.bill.id,
                billRepository: ref.read(billRepositoryProvider),
                paymentRepository: ref.read(billPaymentRepositoryProvider),
              );
              return BillHistoryScreen(controller: historyController);
            },
          ),
        );
      },
    );
  }
}
