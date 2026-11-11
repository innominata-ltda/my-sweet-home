enum GlobalSearchResultType { product, expense, task, recipe, shoppingList }

class GlobalSearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final GlobalSearchResultType type;
  final String targetId;

  const GlobalSearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.targetId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalSearchResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          subtitle == other.subtitle &&
          type == other.type &&
          targetId == other.targetId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      type.hashCode ^
      targetId.hashCode;
}

class GlobalSearchResults {
  final List<GlobalSearchResult> items;

  const GlobalSearchResults({required this.items});

  Map<GlobalSearchResultType, List<GlobalSearchResult>> get groupedByType {
    final map = <GlobalSearchResultType, List<GlobalSearchResult>>{
      for (final type in GlobalSearchResultType.values) type: [],
    };
    for (final item in items) {
      map[item.type]?.add(item);
    }
    return map;
  }
}
