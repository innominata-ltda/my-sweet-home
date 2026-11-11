import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/global_search_repository.dart';

class DriftGlobalSearchRepository implements GlobalSearchRepository {
  const DriftGlobalSearchRepository(this._db);

  final AppDatabase _db;

  static const List<String> _kinds = [
    'product',
    'expense',
    'task',
    'recipe',
    'shoppingList',
  ];

  static String _buildFtsQuery(String input) {
    // Remove caracteres especiais de sintaxe do FTS5
    final sanitized = input
        .replaceAll(RegExp(r'["\*\:\^\(\)\{\}\+\-\?]'), ' ')
        .trim();
    final tokens = sanitized
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3)
        .toList();
    if (tokens.isEmpty) return '';
    // Each term in quotes for trigram substring query
    return tokens.map((t) => '"$t"').join(' ');
  }

  GlobalSearchResultType? _parseType(String kind) {
    switch (kind) {
      case 'product':
        return GlobalSearchResultType.product;
      case 'expense':
        return GlobalSearchResultType.expense;
      case 'task':
        return GlobalSearchResultType.task;
      case 'recipe':
        return GlobalSearchResultType.recipe;
      case 'shoppingList':
        return GlobalSearchResultType.shoppingList;
      default:
        return null;
    }
  }

  @override
  Future<Result<GlobalSearchResults, Failure>> search(
    String query, {
    int limitPerType = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const Ok(GlobalSearchResults(items: []));
    }

    try {
      final List<QueryRow> rows;
      final ftsQuery = trimmed.length >= 3 ? _buildFtsQuery(trimmed) : '';

      if (ftsQuery.isNotEmpty) {
        // FTS5 trigram MATCH with UNION ALL per type to ensure balanced limit
        final sql = _kinds
            .map(
              (k) =>
                  'SELECT kind, target_id, title, body FROM ('
                  'SELECT kind, target_id, title, body FROM search_index '
                  'WHERE search_index MATCH ? AND kind = \'$k\' LIMIT ?'
                  ')',
            )
            .join(' UNION ALL ');

        final variables = <Variable>[];
        for (var i = 0; i < _kinds.length; i++) {
          variables.add(Variable.withString(ftsQuery));
          variables.add(Variable.withInt(limitPerType));
        }

        rows = await _db.customSelect(sql, variables: variables).get();
      } else {
        // LIKE fallback over search_index itself for short queries (1-2 characters)
        final pattern = '%$trimmed%';
        final sql = _kinds
            .map(
              (k) =>
                  'SELECT kind, target_id, title, body FROM ('
                  'SELECT kind, target_id, title, body FROM search_index '
                  'WHERE (title LIKE ? OR body LIKE ?) AND kind = \'$k\' LIMIT ?'
                  ')',
            )
            .join(' UNION ALL ');

        final variables = <Variable>[];
        for (var i = 0; i < _kinds.length; i++) {
          variables.add(Variable.withString(pattern));
          variables.add(Variable.withString(pattern));
          variables.add(Variable.withInt(limitPerType));
        }

        rows = await _db.customSelect(sql, variables: variables).get();
      }

      final counts = <GlobalSearchResultType, int>{};
      final seen = <String>{};
      final items = <GlobalSearchResult>[];

      for (final row in rows) {
        final kind = row.read<String>('kind');
        final targetId = row.read<String>('target_id');
        final title = row.read<String>('title');
        final body = row.read<String>('body');

        final type = _parseType(kind);
        if (type == null) continue;

        final key = '$kind:$targetId';
        if (!seen.add(key)) continue;

        final currentCount = counts[type] ?? 0;
        if (currentCount >= limitPerType) continue;
        counts[type] = currentCount + 1;

        final String id;
        final String itemTitle;
        final String? subtitle;

        switch (type) {
          case GlobalSearchResultType.product:
            id = 'product_$targetId';
            itemTitle = title;
            subtitle = 'Produto';
            break;
          case GlobalSearchResultType.expense:
            id = 'expense_$targetId';
            itemTitle = title.isNotEmpty ? title : 'Despesa';
            subtitle = body.isNotEmpty ? body : null;
            break;
          case GlobalSearchResultType.task:
            id = 'task_$targetId';
            itemTitle = title;
            subtitle = body.isNotEmpty ? body : null;
            break;
          case GlobalSearchResultType.recipe:
            id = 'recipe_$targetId';
            itemTitle = title;
            subtitle = body.isNotEmpty ? body : null;
            break;
          case GlobalSearchResultType.shoppingList:
            id = 'shopping_list_$targetId';
            itemTitle = title;
            subtitle = 'Lista de compras';
            break;
        }

        items.add(
          GlobalSearchResult(
            id: id,
            title: itemTitle,
            subtitle: subtitle,
            type: type,
            targetId: targetId,
          ),
        );
      }

      return Ok(GlobalSearchResults(items: items));
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro na busca global', cause: e));
    }
  }
}
