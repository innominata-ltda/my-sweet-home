import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';

abstract interface class ChecklistRepository {
  Future<Result<List<ChecklistItem>, Failure>> getItems({String? roomCategory});
  Future<Result<List<String>, Failure>> getRoomCategories();
  Future<Result<ChecklistItem, Failure>> addItem({
    required String roomCategory,
    required String title,
  });
  Future<Result<ChecklistItem, Failure>> toggleItemMarked(String id);
  Future<Result<ChecklistItem, Failure>> updateItemTitle(
    String id,
    String newTitle,
  );
  Future<Result<void, Failure>> deleteItem(String id);
  Future<Result<void, Failure>> seedDefaultsIfEmpty();
}
