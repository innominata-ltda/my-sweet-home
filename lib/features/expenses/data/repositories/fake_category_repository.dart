import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';

class FakeCategoryRepository implements CategoryRepository {
  final Map<String, Category> _data = {};
  bool _defaultsSeeded = false;
  int _insertedCount = 0;

  FakeCategoryRepository({List<Category>? initialCategories}) {
    if (initialCategories != null) {
      for (final c in initialCategories) {
        _data[c.id.value] = c;
      }
    }
  }

  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async {
    return Ok(_data.values.where((c) => c.kind == kind).toList());
  }

  @override
  Future<Result<Category, Failure>> upsert(Category c) async {
    _data[c.id.value] = c;
    return Ok(c);
  }

  @override
  Future<Result<void, Failure>> deactivate(CategoryId id) async {
    // Para fins do fake test sem depender de expenses_repository
    // assume there are no pending expenses if removed directly,
    // ou deixamos o teste setar um mock. O teste dita se pode apagar.
    _data.remove(id.value);
    return const Ok(null);
  }

  @override
  Future<Result<int, Failure>> ensureDefaults() async {
    if (_defaultsSeeded) return const Ok(0);
    _defaultsSeeded = true;
    _insertedCount = 10;

    // Insere falsos defaults
    for (int i = 0; i < 10; i++) {
      final id = 'cat_fake_$i';
      _data[id] = Category(
        id: CategoryId(id),
        name: 'Cat $i',
        kind: CategoryKind.expense,
        iconKey: 'icon_$i',
        isSystem: true,
      );
    }

    return Ok(_insertedCount);
  }
}
