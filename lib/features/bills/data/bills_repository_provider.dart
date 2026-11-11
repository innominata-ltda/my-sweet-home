import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/bills/data/adapters/battery_optimization_adapter.dart';
import 'package:my_sweet_home/features/bills/data/adapters/battery_warning_storage_adapter.dart';
import 'package:my_sweet_home/features/bills/data/drift_bills_preferences.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_service.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bills_preferences.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return DriftBillRepository(
    ref.watch(databaseProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final billPaymentRepositoryProvider = Provider<BillPaymentRepository>((ref) {
  return DriftBillPaymentRepository(ref.watch(databaseProvider));
});

final billsPreferencesProvider = Provider<BillsPreferences>((ref) {
  return DriftBillsPreferences(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});

final batteryWarningServiceProvider = Provider<BatteryWarningService>((ref) {
  return BatteryWarningService(
    BatteryOptimizationAdapter(),
    BatteryWarningStorageAdapter(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  );
});
