extension type const CategoryId(String value) {}

enum CategoryKind { expense, product, task, recipe }

class Category {
  final CategoryId id;
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final String? colorHex;
  final bool isSystem;
  final int? sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    this.colorHex,
    required this.isSystem,
    this.sortOrder,
  });
}
