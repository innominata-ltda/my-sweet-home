/// Entidades e enums da mascote Momo (SPEC-012, RF-110, RN-258, RN-259, RN-260, RN-261, RN-262, RN-266).
///
/// This file belongs to pure domain and MUST NOT import Flutter, Drift or I/O.
library;

/// Tipos de animais suportados pela mascote (RN-259).
enum MascotAnimal {
  cat('Gato'),
  dog('Cachorro'),
  bunny('Coelho');

  const MascotAnimal(this.label);
  final String label;

  static MascotAnimal parse(
    String? raw, {
    MascotAnimal fallback = MascotAnimal.cat,
  }) {
    if (raw == null) return fallback;
    final trimmed = raw.trim().toLowerCase();
    for (final animal in values) {
      if (animal.name.toLowerCase() == trimmed ||
          animal.label.toLowerCase() == trimmed) {
        return animal;
      }
    }
    return fallback;
  }
}

/// Emotional expressions supported by mascot (RN-260).
enum MascotExpression {
  neutral,
  happy,
  worried,
  sleepy,
  pointing,
  waving,
  thinking,
  relaxed,
  shopping,
  budget;

  static MascotExpression parse(
    String? raw, {
    MascotExpression fallback = MascotExpression.neutral,
  }) {
    if (raw == null) return fallback;
    final trimmed = raw.trim().toLowerCase();
    for (final exp in values) {
      if (exp.name.toLowerCase() == trimmed) {
        return exp;
      }
    }
    return fallback;
  }

  /// Contextual semantic description in pt-BR (RN-289, A11Y-3).
  String defaultSemanticDescription(String mascotName) {
    final resolvedName = mascotName.trim().isEmpty
        ? MascotConfig.defaultMomo.name
        : mascotName.trim();
    return switch (this) {
      MascotExpression.neutral =>
        '$resolvedName está te acompanhando com atenção',
      MascotExpression.happy =>
        '$resolvedName está muito feliz com o seu progresso',
      MascotExpression.worried =>
        '$resolvedName está com carinha de preocupação',
      MascotExpression.sleepy => '$resolvedName está com soninho e descansando',
      MascotExpression.pointing =>
        '$resolvedName está apontando para esta seção',
      MascotExpression.waving =>
        '$resolvedName está dando um oizinho carinhoso',
      MascotExpression.thinking => '$resolvedName está pensando com carinho',
      MascotExpression.relaxed => '$resolvedName está relaxando tranquilamente',
      MascotExpression.shopping =>
        '$resolvedName está animada para as comprinhas',
      MascotExpression.budget => '$resolvedName está de olho no orçamento',
    };
  }
}

/// Accessories available for mascot (RN-261).
enum MascotAccessory {
  none('Nenhum'),
  bow('Lacinho'),
  collar('Coleira'),
  scarf('Lenço');

  const MascotAccessory(this.label);
  final String label;

  static MascotAccessory parse(
    String? raw, {
    MascotAccessory fallback = MascotAccessory.none,
  }) {
    if (raw == null) return fallback;
    final trimmed = raw.trim().toLowerCase();
    for (final acc in values) {
      if (acc.name.toLowerCase() == trimmed ||
          acc.label.toLowerCase() == trimmed ||
          (acc == MascotAccessory.scarf &&
              (trimmed == 'lenco' || trimmed == 'lenço'))) {
        return acc;
      }
    }
    return fallback;
  }
}

/// Paletas de cores nominais suportadas (RN-266).
enum MascotPalette {
  rose('Rose'),
  lavender('Lavender'),
  mint('Mint');

  const MascotPalette(this.label);
  final String label;

  static MascotPalette parse(
    String? raw, {
    MascotPalette fallback = MascotPalette.rose,
  }) {
    if (raw == null) return fallback;
    final trimmed = raw.trim().toLowerCase();
    for (final pal in values) {
      if (pal.name.toLowerCase() == trimmed ||
          pal.label.toLowerCase() == trimmed) {
        return pal;
      }
    }
    return fallback;
  }
}

/// Custom mascot configuration (RN-258, RN-262).
final class MascotConfig {
  const MascotConfig({
    required this.animal,
    required this.palette,
    required this.accessory,
    required this.name,
  });

  final MascotAnimal animal;
  final MascotPalette palette;
  final MascotAccessory accessory;
  final String name;

  /// Formatted name for display, ensuring fallback to "Momo" if empty or blank.
  String get displayName =>
      name.trim().isEmpty ? defaultMomo.name : name.trim();

  /// Default configuration: cat "Momo", Rose palette, no accessory (RN-262, CA-110.1).
  static const defaultMomo = MascotConfig(
    animal: MascotAnimal.cat,
    palette: MascotPalette.rose,
    accessory: MascotAccessory.none,
    name: 'Momo',
  );

  MascotConfig copyWith({
    MascotAnimal? animal,
    MascotPalette? palette,
    MascotAccessory? accessory,
    String? name,
  }) {
    return MascotConfig(
      animal: animal ?? this.animal,
      palette: palette ?? this.palette,
      accessory: accessory ?? this.accessory,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal': animal.name,
      'palette': palette.name,
      'accessory': accessory.name,
      'name': name,
    };
  }

  factory MascotConfig.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim();
    return MascotConfig(
      animal: MascotAnimal.parse(json['animal']?.toString()),
      palette: MascotPalette.parse(json['palette']?.toString()),
      accessory: MascotAccessory.parse(json['accessory']?.toString()),
      name: (rawName != null && rawName.isNotEmpty)
          ? rawName
          : defaultMomo.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MascotConfig &&
        other.animal == animal &&
        other.palette == palette &&
        other.accessory == accessory &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(animal, palette, accessory, name);

  @override
  String toString() =>
      'MascotConfig(animal: ${animal.name}, palette: ${palette.name}, accessory: ${accessory.name}, name: "$name")';
}
