import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/data/stock_repository_provider.dart';
import 'package:my_sweet_home/features/extras/domain/stock_consumption_estimate.dart';
import 'package:my_sweet_home/features/extras/domain/stock_item.dart';
import 'package:my_sweet_home/features/extras/domain/stock_repository.dart';

class StockState {
  const StockState({
    this.isLoading = false,
    this.items = const [],
    this.failure,
  });

  final bool isLoading;
  final List<StockItem> items;
  final Failure? failure;

  StockState copyWith({
    bool? isLoading,
    List<StockItem>? items,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return StockState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class StockController extends ValueNotifier<StockState> {
  StockController(this._repository) : super(const StockState()) {
    loadStockItems();
  }

  final StockRepository _repository;

  Future<void> loadStockItems() async {
    value = value.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getStockItems();
    result.fold(
      (items) => value = value.copyWith(isLoading: false, items: items),
      (failure) => value = value.copyWith(isLoading: false, failure: failure),
    );
  }

  Future<void> updateQuantity({
    required String productId,
    required Quantity quantity,
    Quantity? lowStockThreshold,
  }) async {
    final res = await _repository.upsertStockItem(
      productId: productId,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
    );
    if (res.isOk) {
      await loadStockItems();
    }
  }

  Future<void> deleteItem(String id) async {
    final res = await _repository.deleteStockItem(id);
    if (res.isOk) {
      await loadStockItems();
    }
  }
}

final stockControllerProvider = Provider.autoDispose<StockController>((ref) {
  final controller = StockController(ref.watch(stockRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

final stockEstimateProvider =
    FutureProvider.family<StockConsumptionEstimate, String>((
      ref,
      productId,
    ) async {
      final repo = ref.watch(stockRepositoryProvider);
      final res = await repo.getConsumptionEstimate(productId);
      return res.fold(
        (estimate) => estimate,
        (failure) => StockConsumptionEstimate(
          productId: productId,
          purchaseCount: 0,
          hasEnoughHistory: false,
        ),
      );
    });
