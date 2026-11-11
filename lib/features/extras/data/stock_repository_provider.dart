import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/extras/data/drift_stock_repository.dart';
import 'package:my_sweet_home/features/extras/domain/stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return DriftStockRepository(
    ref.watch(databaseProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
});
