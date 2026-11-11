/// Area of a household task preset (SPEC-014).
enum TaskPresetArea {
  kitchen('Cozinha'),
  bathroom('Banheiro'),
  bedroom('Quarto'),
  laundry('Roupas'),
  generalCleaning('Limpeza geral'),
  shopping('Compras');

  const TaskPresetArea(this.label);
  final String label;

  static TaskPresetArea fromName(String name) {
    return TaskPresetArea.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ArgumentError('Área desconhecida: $name'),
    );
  }
}

/// Task preset with suggested frequency and rationale (SPEC-014).
final class TaskPreset {
  const TaskPreset({
    required this.id,
    required this.area,
    required this.title,
    required this.recommendedRrule,
    required this.rationale,
  });

  final String id;
  final TaskPresetArea area;
  final String title;
  final String recommendedRrule;
  final String rationale;

  factory TaskPreset.fromJson(Map<String, dynamic> json) {
    return TaskPreset(
      id: json['id'] as String,
      area: TaskPresetArea.fromName(json['area'] as String),
      title: json['title'] as String,
      recommendedRrule: json['recommendedRrule'] as String,
      rationale: json['rationale'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'area': area.name,
    'title': title,
    'recommendedRrule': recommendedRrule,
    'rationale': rationale,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPreset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Immutable versioned catalog of task presets (SPEC-014).
final class TaskPresetCatalog {
  const TaskPresetCatalog({required this.version, required this.presets});

  final int version;
  final List<TaskPreset> presets;

  factory TaskPresetCatalog.fromJson(Map<String, dynamic> json) {
    final list = (json['presets'] as List<dynamic>?) ?? [];
    return TaskPresetCatalog(
      version: json['version'] as int? ?? 1,
      presets: list
          .map((item) => TaskPreset.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'presets': presets.map((p) => p.toJson()).toList(),
  };
}
