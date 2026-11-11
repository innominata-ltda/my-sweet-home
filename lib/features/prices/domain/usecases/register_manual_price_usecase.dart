import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';

/// Use case to register a standalone price in history (RN-063).
class RegisterManualPriceUseCase {
  const RegisterManualPriceUseCase({
    required this.pricePointRepository,
    required this.idGenerator,
    required this.clock,
  });

  final PricePointRepository pricePointRepository;
  final IdGenerator idGenerator;
  final Clock clock;

  Future<Result<void, Failure>> call({
    required String productId,
    required String storeId,
    required Money price,
    required Quantity quantity,
    DateTime? date,
  }) async {
    final pointDate = date ?? clock.nowUtc();

    final point = PricePoint.manual(
      id: idGenerator.newId(),
      productId: productId,
      storeId: storeId,
      date: pointDate,
      price: price,
      quantity: quantity,
    );

    return pricePointRepository.saveAll([point]);
  }
}
