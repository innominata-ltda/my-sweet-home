import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/global_search_repository.dart';

class FakeGlobalSearchRepository implements GlobalSearchRepository {
  FakeGlobalSearchRepository([List<GlobalSearchResult>? initialItems])
    : _items = List.from(initialItems ?? []);

  final List<GlobalSearchResult> _items;

  void addItem(GlobalSearchResult item) {
    _items.add(item);
  }

  void addItems(List<GlobalSearchResult> items) {
    _items.addAll(items);
  }

  void clear() {
    _items.clear();
  }

  @override
  Future<Result<GlobalSearchResults, Failure>> search(
    String query, {
    int limitPerType = 20,
  }) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return const Ok(GlobalSearchResults(items: []));
    }

    final matched = _items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(trimmed);
      final subtitleMatch =
          item.subtitle?.toLowerCase().contains(trimmed) ?? false;
      return titleMatch || subtitleMatch;
    }).toList();

    return Ok(GlobalSearchResults(items: matched));
  }
}
