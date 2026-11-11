import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

abstract interface class CategoryRepository {
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  });
  Future<Result<Category, Failure>> upsert(Category c);
  Future<Result<void, Failure>> deactivate(CategoryId id);
  Future<Result<int, Failure>> ensureDefaults();
}
