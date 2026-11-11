import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout_repository.dart';

sealed class DashboardLayoutState {
  const DashboardLayoutState();
}

class DashboardLayoutLoading extends DashboardLayoutState {
  const DashboardLayoutLoading();
}

class DashboardLayoutLoaded extends DashboardLayoutState {
  final DashboardLayoutConfig config;

  const DashboardLayoutLoaded(this.config);

  List<DashboardItemKind> get visibleItems => config.visibleItems;
  List<DashboardItemKind> get hiddenItems => config.hiddenItems;
  bool get isEmpty => config.visibleItems.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutLoaded && config == other.config;

  @override
  int get hashCode => config.hashCode;
}

class DashboardLayoutError extends DashboardLayoutState {
  final Failure failure;
  const DashboardLayoutError(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutError && failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

/// Controller responsible for state and actions of Dashboard layout customization (RN-372, RN-373, RN-375).
class DashboardLayoutController extends ValueNotifier<DashboardLayoutState> {
  DashboardLayoutController({required this.repository})
    : super(const DashboardLayoutLoading()) {
    unawaited(load());
  }

  final DashboardLayoutRepository repository;
  DashboardLayoutRepository get _repository => repository;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(DashboardLayoutState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  DashboardLayoutConfig get currentConfig {
    final state = value;
    if (state is DashboardLayoutLoaded) {
      return state.config;
    }
    return const DashboardLayoutConfig(
      visibleItems: DashboardLayoutConfig.defaultOrder,
    );
  }

  Future<void> load() async {
    value = const DashboardLayoutLoading();
    final result = await _repository.load();
    result.fold(
      (config) => value = DashboardLayoutLoaded(config),
      (failure) => value = DashboardLayoutError(failure),
    );
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final updated = currentConfig.reorder(oldIndex, newIndex);
    await _applyAndPersist(updated);
  }

  Future<void> moveUp(DashboardItemKind kind) async {
    final updated = currentConfig.moveUp(kind);
    await _applyAndPersist(updated);
  }

  Future<void> moveDown(DashboardItemKind kind) async {
    final updated = currentConfig.moveDown(kind);
    await _applyAndPersist(updated);
  }

  Future<void> hide(DashboardItemKind kind) async {
    final updated = currentConfig.hide(kind);
    await _applyAndPersist(updated);
  }

  Future<void> show(DashboardItemKind kind) async {
    final updated = currentConfig.show(kind);
    await _applyAndPersist(updated);
  }

  Future<void> resetToDefault() async {
    final result = await _repository.resetToDefault();
    result.fold(
      (config) => value = DashboardLayoutLoaded(config),
      (failure) => value = DashboardLayoutError(failure),
    );
  }

  Future<void> _applyAndPersist(DashboardLayoutConfig config) async {
    value = DashboardLayoutLoaded(config);
    final result = await _repository.save(config);
    result.fold(
      (saved) => value = DashboardLayoutLoaded(saved),
      (failure) => value = DashboardLayoutError(failure),
    );
  }
}
