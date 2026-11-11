import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/shopping/domain/models/known_price.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/services/estimate_policy.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/get_list_estimate_usecase.dart';

// ---------------------------------------------------------------------------
// Fake PricePointRepository
// ---------------------------------------------------------------------------

class _FakePricePointRepository implements PricePointRepository {
  _FakePricePointRepository(this._data);

  /// productId → list of PricePoints
  final Map<String, List<PricePoint>> _data;

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async => const Ok(null);

  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async => Ok(_data[productId] ?? []);

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async => const Ok(
    PriceStats(averagePrice: Money.zero, observationsCount: 0, windowDays: 30),
  );

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async => const Ok([]);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ShoppingItem _item({required String id, String? productId}) =>
    ShoppingItem(id: id, rawText: id, parsedName: id, productId: productId);

PricePoint _pricePoint({
  required String productId,
  required String storeId,
  required Money price,
  DateTime? date,
}) => PricePoint(
  id: '$productId-$storeId',
  productId: productId,
  storeId: storeId,
  date: date ?? DateTime(2026, 8, 12),
  normalizedPrice: price,
  unit: Unit.un,
  source: PricePointSource.purchase,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DefaultEstimatePolicy', () {
    late DefaultEstimatePolicy policy;

    setUp(() {
      policy = const DefaultEstimatePolicy();
    });

    // CA-2.1 — 1 item with price, 1 without -> known=2490, itemsWithoutPrice=1
    test('CA-2.1: separates priced item and unpriced item', () {
      final items = [
        _item(id: 'arroz', productId: 'prod-arroz'),
        _item(id: 'sal'), // without productId -> without price
      ];

      final lastPrices = {
        'prod-arroz': KnownPrice(
          price: const Money(2490), // R$ 24,90
          recordedAt: DateTime(2026, 8, 12),
          storeId: 'loja-a',
        ),
      };

      final estimate = policy.estimate(items: items, lastPrices: lastPrices);

      expect(estimate.known, const Money(2490));
      expect(estimate.itemsWithoutPrice, 1);
      expect(estimate.oldestPriceUsed, DateTime(2026, 8, 12));
    });

    test(
      'CA-2.1: item com productId mas sem entrada no mapa conta como sem preço',
      () {
        final items = [_item(id: 'feijão', productId: 'prod-feijao')];

        final estimate = policy.estimate(items: items, lastPrices: {});

        expect(estimate.known, Money.zero);
        expect(estimate.itemsWithoutPrice, 1);
        expect(estimate.oldestPriceUsed, isNull);
      },
    );

    test('Empty list yields zero estimate without unpriced items', () {
      final estimate = policy.estimate(items: [], lastPrices: {});

      expect(estimate.known, Money.zero);
      expect(estimate.itemsWithoutPrice, 0);
      expect(estimate.oldestPriceUsed, isNull);
    });

    test('All items with price -> itemsWithoutPrice = 0', () {
      final items = [
        _item(id: 'arroz', productId: 'prod-arroz'),
        _item(id: 'feijão', productId: 'prod-feijao'),
      ];

      final lastPrices = {
        'prod-arroz': KnownPrice(
          price: const Money(2490),
          recordedAt: DateTime(2026, 8, 12),
          storeId: 'loja-a',
        ),
        'prod-feijao': KnownPrice(
          price: const Money(899),
          recordedAt: DateTime(2026, 8, 10),
          storeId: 'loja-a',
        ),
      };

      final estimate = policy.estimate(items: items, lastPrices: lastPrices);

      expect(estimate.known, const Money(3389)); // 2490 + 899
      expect(estimate.itemsWithoutPrice, 0);
      expect(estimate.isComplete, isTrue);
      // oldestPriceUsed = 10 de agosto (mais antigo entre os dois)
      expect(estimate.oldestPriceUsed, DateTime(2026, 8, 10));
    });

    test(
      'oldestPriceUsed aponta para a data mais antiga entre os preços usados',
      () {
        final items = [
          _item(id: 'a', productId: 'prod-a'),
          _item(id: 'b', productId: 'prod-b'),
          _item(id: 'c', productId: 'prod-c'),
        ];

        final lastPrices = {
          'prod-a': KnownPrice(
            price: const Money(100),
            recordedAt: DateTime(2026, 7, 1), // mais antigo
            storeId: 'loja-x',
          ),
          'prod-b': KnownPrice(
            price: const Money(200),
            recordedAt: DateTime(2026, 9, 1),
            storeId: 'loja-x',
          ),
          'prod-c': KnownPrice(
            price: const Money(300),
            recordedAt: DateTime(2026, 8, 15),
            storeId: 'loja-x',
          ),
        };

        final estimate = policy.estimate(items: items, lastPrices: lastPrices);

        expect(estimate.oldestPriceUsed, DateTime(2026, 7, 1));
      },
    );

    test('Items marked as purchased are included in estimate', () {
      final items = [
        ShoppingItem(
          id: 'arroz',
          rawText: 'arroz',
          parsedName: 'arroz',
          productId: 'prod-arroz',
          boughtAt: DateTime(2026, 9, 1), // already checked
        ),
      ];

      final lastPrices = {
        'prod-arroz': KnownPrice(
          price: const Money(2490),
          recordedAt: DateTime(2026, 8, 12),
          storeId: 'loja-a',
        ),
      };

      // Checked items must appear in estimate (user checks at checkout).
      final estimate = policy.estimate(items: items, lastPrices: lastPrices);
      expect(estimate.known, const Money(2490));
      expect(estimate.itemsWithoutPrice, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // GetListEstimateUseCase - integration with fake repository (CA-2.2)
  // ---------------------------------------------------------------------------

  group('GetListEstimateUseCase', () {
    // CA-2.2 — list associated with Store A prefers price of A over B
    test(
      'CA-2.2: prefere preço do mercado da lista quando disponível',
      () async {
        const productId = 'prod-arroz';

        final fakeRepo = _FakePricePointRepository({
          productId: [
            _pricePoint(
              productId: productId,
              storeId: 'loja-a',
              price: const Money(2490), // R$ 24,90 — preferido
              date: DateTime(2026, 8, 12),
            ),
            _pricePoint(
              productId: productId,
              storeId: 'loja-b',
              price: const Money(2200), // R$ 22,00
              date: DateTime(2026, 9, 1), // mais recente, mas mercado errado
            ),
          ],
        });

        final list = ShoppingList(
          id: 'lista-1',
          name: 'Mercado do mês',
          createdAt: DateTime(2026, 9, 15),
          storeId: 'loja-a', // preference for Store A
          items: [_item(id: 'arroz', productId: productId)],
        );

        final useCase = GetListEstimateUseCase(
          priceRepository: fakeRepo,
          policy: const DefaultEstimatePolicy(),
        );

        final result = await useCase(list);

        expect(result.isOk, isTrue);
        final estimate = result.valueOrNull!;

        // Must use R$ 24.90 (Store A), not R$ 22.00 (Store B newer)
        expect(estimate.known, const Money(2490));
        expect(estimate.itemsWithoutPrice, 0);
      },
    );

    test('CA-2.2: uses latest price of any store when preferred store price is absent', () async {
      const productId = 'prod-feijao';

      final fakeRepo = _FakePricePointRepository({
        productId: [
          _pricePoint(
            productId: productId,
            storeId: 'loja-b',
            price: const Money(1000),
            date: DateTime(2026, 7, 1),
          ),
          _pricePoint(
            productId: productId,
            storeId: 'loja-c',
            price: const Money(1200),
            date: DateTime(2026, 9, 1), // mais recente
          ),
        ],
      });

      final list = ShoppingList(
        id: 'lista-2',
        name: 'Feirinha',
        createdAt: DateTime(2026, 9, 15),
        storeId: 'loja-a', // Store A has no price for the product
        items: [_item(id: 'feijão', productId: productId)],
      );

      final useCase = GetListEstimateUseCase(
        priceRepository: fakeRepo,
        policy: const DefaultEstimatePolicy(),
      );

      final result = await useCase(list);

      expect(result.isOk, isTrue);
      final estimate = result.valueOrNull!;

      // No price in Store A -> uses overall latest (Store C, R$ 12.00)
      expect(estimate.known, const Money(1200));
      expect(estimate.itemsWithoutPrice, 0);
    });

    test(
      'List without productId in any item returns everything unpriced',
      () async {
        final fakeRepo = _FakePricePointRepository({});

        final list = ShoppingList(
          id: 'lista-3',
          name: 'Lista',
          createdAt: DateTime(2026, 9, 15),
          items: [
            _item(id: 'qualquer-coisa'),
            _item(id: 'outra-coisa'),
          ],
        );

        final useCase = GetListEstimateUseCase(
          priceRepository: fakeRepo,
          policy: const DefaultEstimatePolicy(),
        );

        final result = await useCase(list);

        expect(result.isOk, isTrue);
        final estimate = result.valueOrNull!;

        expect(estimate.known, Money.zero);
        expect(estimate.itemsWithoutPrice, 2);
      },
    );

    test('Lista vazia retorna estimativa zerada', () async {
      final fakeRepo = _FakePricePointRepository({});

      final list = ShoppingList(
        id: 'lista-4',
        name: 'Lista vazia',
        createdAt: DateTime(2026, 9, 15),
      );

      final useCase = GetListEstimateUseCase(
        priceRepository: fakeRepo,
        policy: const DefaultEstimatePolicy(),
      );

      final result = await useCase(list);

      expect(result.isOk, isTrue);
      final estimate = result.valueOrNull!;

      expect(estimate.known, Money.zero);
      expect(estimate.itemsWithoutPrice, 0);
      expect(estimate.isComplete, isTrue);
    });

    test('Propagates Err from repository', () async {
      // Repository that always fails
      final failingRepo = _FailingPricePointRepository();

      final list = ShoppingList(
        id: 'lista-5',
        name: 'Lista com erro',
        createdAt: DateTime(2026, 9, 15),
        items: [_item(id: 'arroz', productId: 'prod-arroz')],
      );

      final useCase = GetListEstimateUseCase(
        priceRepository: failingRepo,
        policy: const DefaultEstimatePolicy(),
      );

      final result = await useCase(list);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // ListEstimate — value object
  // ---------------------------------------------------------------------------

  group('ListEstimate', () {
    test('isComplete is true when itemsWithoutPrice == 0', () {
      const estimate = ListEstimate(known: Money(100), itemsWithoutPrice: 0);
      expect(estimate.isComplete, isTrue);
    });

    test('isComplete is false when there are unpriced items', () {
      const estimate = ListEstimate(known: Money(100), itemsWithoutPrice: 3);
      expect(estimate.isComplete, isFalse);
    });

    test('equality por valor', () {
      final a = ListEstimate(
        known: const Money(500),
        itemsWithoutPrice: 2,
        oldestPriceUsed: DateTime(2026, 8, 1),
      );
      final b = ListEstimate(
        known: const Money(500),
        itemsWithoutPrice: 2,
        oldestPriceUsed: DateTime(2026, 8, 1),
      );
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // KnownPrice — value object
  // ---------------------------------------------------------------------------

  group('KnownPrice', () {
    test('equality por valor', () {
      final d = DateTime(2026, 8, 12);
      final a = KnownPrice(
        price: const Money(2490),
        recordedAt: d,
        storeId: 'loja-a',
      );
      final b = KnownPrice(
        price: const Money(2490),
        recordedAt: d,
        storeId: 'loja-a',
      );
      expect(a, equals(b));
    });

    test('desigualdade quando storeId difere', () {
      final d = DateTime(2026, 8, 12);
      final a = KnownPrice(
        price: const Money(2490),
        recordedAt: d,
        storeId: 'loja-a',
      );
      final b = KnownPrice(
        price: const Money(2490),
        recordedAt: d,
        storeId: 'loja-b',
      );
      expect(a, isNot(equals(b)));
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: repository that always fails
// ---------------------------------------------------------------------------

class _FailingPricePointRepository implements PricePointRepository {
  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async => const Err(StorageFailure(detail: 'falha simulada'));

  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async => const Err(StorageFailure(detail: 'falha simulada'));

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async => const Err(StorageFailure(detail: 'falha simulada'));

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async => const Err(StorageFailure(detail: 'falha simulada'));
}
