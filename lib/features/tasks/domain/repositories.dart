import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';

import 'models.dart';

abstract interface class TaskRepository {
  Future<Result<Task, Failure>> upsert(NewTask t);
  Future<Result<Task, Failure>> complete(
    TaskId id,
  ); // recurrent generates next occurrence (RN-151)
  Future<Result<Task, Failure>> uncomplete(TaskId id);
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  });
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r);
  Future<Result<List<Task>, Failure>> withoutDueDate();
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark);
  Future<Result<List<Task>, Failure>> allTasksForSync();
  Future<Result<Task, Failure>> saveSyncedTask(Task task);
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id);
}
