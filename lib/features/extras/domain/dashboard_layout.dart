/// Closed catalog of available cards in the Dashboard (RN-370).
enum DashboardItemKind {
  mascotGreeting, // Mascot greeting
  monthBalance, // Month balance
  dueBills, // Contas a Vencer
  todayTasks, // Tarefas de Hoje
  shoppingList, // Lista de Compras
  stockAlert, // Household stock
  firstHomeChecklist, // Checklist da Primeira Casa
  economyGoal, // Modo Economia
  favoriteRecipes, // Receitas
}

/// Immutable order and visibility state of the Dashboard (RN-371, RN-372, RN-373).
final class DashboardLayoutConfig {
  const DashboardLayoutConfig({required this.visibleItems});

  /// Default order on fresh install (RN-371).
  static const List<DashboardItemKind> defaultOrder = [
    DashboardItemKind.mascotGreeting,
    DashboardItemKind.monthBalance,
    DashboardItemKind.dueBills,
    DashboardItemKind.todayTasks,
    DashboardItemKind.shoppingList,
  ];

  final List<DashboardItemKind> visibleItems;

  /// Catalog items currently hidden and available for addition.
  List<DashboardItemKind> get hiddenItems => [
    for (final kind in DashboardItemKind.values)
      if (!visibleItems.contains(kind)) kind,
  ];

  /// Reordena o item em [oldIndex] para [newIndex], tratando o ajuste
  /// standard drag-and-drop pattern when [oldIndex] < [newIndex] (RN-372).
  DashboardLayoutConfig reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= visibleItems.length) return this;
    var target = newIndex;
    if (oldIndex < target) {
      target -= 1;
    }
    if (target < 0) target = 0;
    if (target >= visibleItems.length) target = visibleItems.length - 1;
    if (oldIndex == target) return this;

    final items = List<DashboardItemKind>.from(visibleItems);
    final item = items.removeAt(oldIndex);
    items.insert(target, item);
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(items));
  }

  /// Moves [kind] one position up if not the first item (RN-372, RN-376).
  DashboardLayoutConfig moveUp(DashboardItemKind kind) {
    final index = visibleItems.indexOf(kind);
    if (index <= 0) return this;
    final items = List<DashboardItemKind>.from(visibleItems);
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(items));
  }

  /// Moves [kind] one position down if not the last item (RN-372, RN-376).
  DashboardLayoutConfig moveDown(DashboardItemKind kind) {
    final index = visibleItems.indexOf(kind);
    if (index < 0 || index >= visibleItems.length - 1) return this;
    final items = List<DashboardItemKind>.from(visibleItems);
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(items));
  }

  /// Hides [kind] from visible list without deleting data (RN-372, RN-373).
  DashboardLayoutConfig hide(DashboardItemKind kind) {
    if (!visibleItems.contains(kind)) return this;
    final items = List<DashboardItemKind>.from(visibleItems)..remove(kind);
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(items));
  }

  /// Adds [kind] to the end of visible list if not already visible (RN-372).
  DashboardLayoutConfig show(DashboardItemKind kind) {
    if (visibleItems.contains(kind)) return this;
    final items = List<DashboardItemKind>.from(visibleItems)..add(kind);
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(items));
  }

  /// Converts visible items list to a JSON-serializable string list (RN-375).
  List<String> toJson() => visibleItems.map((e) => e.name).toList();

  /// Desserializa a partir de lista de strings JSON (RN-375).
  /// If list is null or element is unknown, ignores invalid items.
  factory DashboardLayoutConfig.fromJson(dynamic json) {
    if (json is! List) {
      return const DashboardLayoutConfig(visibleItems: defaultOrder);
    }
    final kinds = <DashboardItemKind>[];
    for (final element in json) {
      if (element is String) {
        for (final kind in DashboardItemKind.values) {
          if (kind.name == element && !kinds.contains(kind)) {
            kinds.add(kind);
            break;
          }
        }
      }
    }
    return DashboardLayoutConfig(visibleItems: List.unmodifiable(kinds));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutConfig &&
          _listEquals(visibleItems, other.visibleItems);

  @override
  int get hashCode => Object.hashAll(visibleItems);

  @override
  String toString() => 'DashboardLayoutConfig(visibleItems: $visibleItems)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
