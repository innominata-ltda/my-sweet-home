import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

const _accentMap = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

String _normalize(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    buf.write(_accentMap[lower[i]] ?? lower[i]);
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Pure search in catalog ignoring case, accents and punctuation (RN-359).
final class TaskPresetSearch {
  const TaskPresetSearch();

  List<TaskPreset> filter({
    required List<TaskPreset> presets,
    required String query,
  }) {
    final normQuery = _normalize(query);
    if (normQuery.isEmpty) return presets;

    final terms = normQuery.split(' ').where((t) => t.isNotEmpty).toList();

    return presets.where((preset) {
      final target =
          '${_normalize(preset.title)} ${_normalize(preset.area.label)}';
      return terms.every(target.contains);
    }).toList();
  }
}
