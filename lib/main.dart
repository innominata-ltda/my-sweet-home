import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/app.dart';
import 'package:my_sweet_home/app/bootstrap.dart';
import 'package:my_sweet_home/app/database_recovery_screen.dart';
import 'package:my_sweet_home/app/error_boundary.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/data/seed_loader.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/data/recurrence/expense_materializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupGlobalErrorHandling();

  try {
    final vault = DefaultDatabaseVault();
    final opening = await vault.open();

    switch (opening) {
      case VaultReady(:final db):
        await _runAppWithDatabase(db);
      case VaultConversionFailed(:final plaintextDb):
        runApp(
          DatabaseRecoveryScreen(
            opening: opening,
            vault: vault,
            onContinueWithPlaintext: () => _runAppWithDatabase(plaintextDb),
          ),
        );
      case VaultKeyUnavailable():
        runApp(
          DatabaseRecoveryScreen(
            opening: opening,
            vault: vault,
            onRestartComplete: () async => main(),
          ),
        );
    }
  } catch (_) {
    runApp(const AppErrorState());
  }
}

Future<void> _runAppWithDatabase(AppDatabase db) async {
  const clock = SystemClock();
  const idGen = UuidV7Generator();

  final seedLoader = SeedLoader(db, idGen, clock);
  await seedLoader.loadIfNeeded();

  final expenseMat = ExpenseMaterializer(db: db, idGenerator: idGen);
  final billRepo = DriftBillRepository(db, idGenerator: idGen);
  final paymentRepo = DriftBillPaymentRepository(db);
  final billMat = BillMaterializer(
    billRepo: billRepo,
    paymentRepo: paymentRepo,
    dueDatePolicy: const StandardDueDatePolicy(),
  );

  final materializerUseCase = DefaultMaterializeRecurrences(
    materializers: [expenseMat, billMat],
    clock: clock,
  );
  final trashPolicy = DriftTrashPolicy.system(db: db);

  await bootstrap(materializerUseCase, trashPolicy: trashPolicy);

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MySweetHomeApp(),
    ),
  );
}
