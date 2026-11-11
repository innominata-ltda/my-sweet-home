import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_customization_state.dart';

/// Canonical contract for mascot Momo controller (SPEC-012, plan.md).
abstract interface class MascotController {
  /// Returns current configuration state in edit/preview.
  MascotConfig get state;

  /// Atualiza o animal selecionado em tempo real (RN-259, CA-110.2).
  void selectAnimal(MascotAnimal animal);

  /// Atualiza a paleta de cores selecionada em tempo real (RN-266, CA-110.2).
  void selectPalette(MascotPalette palette);

  /// Updates selected accessory in real time (RN-261, CA-110.2).
  void selectAccessory(MascotAccessory accessory);

  /// Atualiza o nome da mascote em tempo real (RN-258, CA-110.2).
  void updateName(String name);

  /// Persists updated configuration to repository (CA-110.3).
  Future<Result<Unit, Failure>> save();

  /// Discards unsaved changes and restores previous state (CA-110.4).
  void cancel();
}

/// Reactive controller implementation for mascot customization screen.
class MascotCustomizationController
    extends ValueNotifier<MascotCustomizationState>
    implements MascotController {
  MascotCustomizationController({
    required this.repository,
    MascotConfig? initialConfig,
  }) : _currentDraft = initialConfig ?? MascotConfig.defaultMomo,
       _initialConfig = initialConfig ?? MascotConfig.defaultMomo,
       super(
         initialConfig != null
             ? MascotCustomizationData(
                 config: initialConfig,
                 initialConfig: initialConfig,
                 isDefault: initialConfig == MascotConfig.defaultMomo,
               )
             : const MascotCustomizationLoading(),
       ) {
    if (initialConfig == null) {
      unawaited(load());
    }
  }

  final MascotRepository repository;
  MascotConfig _currentDraft;
  MascotConfig _initialConfig;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(MascotCustomizationState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  @override
  MascotConfig get state => _currentDraft;

  /// Loads persisted preferences from repository.
  Future<void> load() async {
    value = const MascotCustomizationLoading();
    try {
      final result = await repository.loadConfig();
      switch (result) {
        case Ok(:final value):
          _currentDraft = value;
          _initialConfig = value;
          this.value = MascotCustomizationData(
            config: value,
            initialConfig: value,
            isDefault: value == MascotConfig.defaultMomo,
          );
        case Err(:final failure):
          value = MascotCustomizationError(_formatFailure(failure));
      }
    } catch (e) {
      value = MascotCustomizationError('Falha ao carregar personalização: $e');
    }
  }

  @override
  void selectAnimal(MascotAnimal animal) {
    _currentDraft = _currentDraft.copyWith(animal: animal);
    _syncData();
  }

  @override
  void selectPalette(MascotPalette palette) {
    _currentDraft = _currentDraft.copyWith(palette: palette);
    _syncData();
  }

  @override
  void selectAccessory(MascotAccessory accessory) {
    _currentDraft = _currentDraft.copyWith(accessory: accessory);
    _syncData();
  }

  @override
  void updateName(String name) {
    _currentDraft = _currentDraft.copyWith(name: name);
    _syncData();
  }

  @override
  void cancel() {
    _currentDraft = _initialConfig;
    _syncData();
  }

  @override
  Future<Result<Unit, Failure>> save() async {
    _syncData(isSaving: true);
    final effectiveName = _currentDraft.name.trim().isEmpty
        ? MascotConfig.defaultMomo.name
        : _currentDraft.name.trim();
    final configToSave = _currentDraft.copyWith(name: effectiveName);

    final result = await repository.saveConfig(configToSave);
    switch (result) {
      case Ok():
        _currentDraft = configToSave;
        _initialConfig = configToSave;
        _syncData();
        return const Ok(null);
      case Err(:final failure):
        _syncData(errorMessage: _formatFailure(failure));
        return Err(failure);
    }
  }

  static String _formatFailure(Failure failure) => userMessageFor(failure);

  void _syncData({bool isSaving = false, String? errorMessage}) {
    value = MascotCustomizationData(
      config: _currentDraft,
      initialConfig: _initialConfig,
      isSaving: isSaving,
      errorMessage: errorMessage,
      isDefault: _currentDraft == MascotConfig.defaultMomo,
    );
  }
}

/// Riverpod provider for mascot customization controller.
final mascotCustomizationControllerProvider =
    Provider.autoDispose<MascotCustomizationController>((ref) {
      final repository = ref.watch(mascotRepositoryProvider);
      final controller = MascotCustomizationController(repository: repository);
      ref.onDispose(controller.dispose);
      return controller;
    });

/// Alias para o provedor do controller da mascote conforme plan.md.
final mascotControllerProvider = mascotCustomizationControllerProvider;
