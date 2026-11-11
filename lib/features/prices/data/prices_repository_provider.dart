import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/prices/data/store/sqlite_store_repository.dart';
import 'package:my_sweet_home/features/prices/domain/store/store_repository.dart';
import 'package:my_sweet_home/features/prices/data/purchase/sqlite_purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/data/price_point/sqlite_price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return SqliteStoreRepository(ref.watch(databaseProvider));
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return SqlitePurchaseRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});

final pricePointRepositoryProvider = Provider<PricePointRepository>((ref) {
  return SqlitePricePointRepository(ref.watch(databaseProvider));
});
