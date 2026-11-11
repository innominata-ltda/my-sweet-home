import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';

/// Use case to save a purchase and generate corresponding price points (RN-052).
class SavePurchaseUseCase {
  const SavePurchaseUseCase({
    required this.purchaseRepository,
    required this.pricePointRepository,
  });

  final PurchaseRepository purchaseRepository;
  final PricePointRepository pricePointRepository;

  Future<Result<void, Failure>> call(Purchase purchase) async {
    // 1. Salvar a compra
    final saveResult = await purchaseRepository.save(purchase);
    if (saveResult is Err) {
      return saveResult;
    }

    // 2. Generate price points from purchase items (RN-052, RN-053)
    final points = purchase.items.map((item) {
      return PricePoint.fromPurchaseItem(
        id: '${purchase.id}_${item.id}',
        storeId: purchase.storeId,
        date: purchase.date,
        item: item,
      );
    }).toList();

    // 3. Save price points
    return pricePointRepository.saveAll(points, purchaseId: purchase.id);
  }
}
