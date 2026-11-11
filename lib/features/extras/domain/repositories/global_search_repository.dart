import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';

abstract interface class GlobalSearchRepository {
  Future<Result<GlobalSearchResults, Failure>> search(
    String query, {
    int limitPerType = 20,
  });
}
