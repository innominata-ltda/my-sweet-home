import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';

/// Possible states of mascot customization screen (SPEC-012, RF-110, RN-263).
sealed class MascotCustomizationState {
  const MascotCustomizationState();
}

/// Initial loading state of mascot preferences.
final class MascotCustomizationLoading extends MascotCustomizationState {
  const MascotCustomizationLoading();
}

/// State with data available for mascot editing and preview.
final class MascotCustomizationData extends MascotCustomizationState {
  const MascotCustomizationData({
    required this.config,
    required this.initialConfig,
    this.isSaving = false,
    this.errorMessage,
    this.isDefault = false,
  });

  /// Draft configuration being edited in real time (CA-110.2).
  final MascotConfig config;

  /// Original persisted configuration before editing started (CA-110.4).
  final MascotConfig initialConfig;

  /// Indicates if persistence operation is in progress.
  final bool isSaving;

  /// Error message if persistence fails.
  final String? errorMessage;

  /// Indicates if current config is initial default ("Momo", cat, Rose, no accessory) (RN-262).
  final bool isDefault;

  /// Indicates if there are unsaved changes relative to initial configuration.
  bool get hasChanges => config != initialConfig;

  MascotCustomizationData copyWith({
    MascotConfig? config,
    MascotConfig? initialConfig,
    bool? isSaving,
    String? errorMessage,
    bool? isDefault,
  }) {
    return MascotCustomizationData(
      config: config ?? this.config,
      initialConfig: initialConfig ?? this.initialConfig,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MascotCustomizationData &&
          runtimeType == other.runtimeType &&
          config == other.config &&
          initialConfig == other.initialConfig &&
          isSaving == other.isSaving &&
          errorMessage == other.errorMessage &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      Object.hash(config, initialConfig, isSaving, errorMessage, isDefault);
}

/// Error state on initial preferences loading failure.
final class MascotCustomizationError extends MascotCustomizationState {
  const MascotCustomizationError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MascotCustomizationError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
