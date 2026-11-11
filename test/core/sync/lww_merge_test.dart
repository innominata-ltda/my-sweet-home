import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/lww_merge.dart';

void main() {
  group('LwwMerge e ColumnVersion (RN-320, RN-321, RN-322, CA-5.1)', () {
    const merge = LwwMerge();

    test('ColumnVersion serializacao, chave e igualdade', () {
      final hlc = Hlc(millis: 1000, counter: 0, siteId: 'dev-1');
      final col = ColumnVersion(
        table: 'products',
        rowId: 'prod-001',
        column: 'canonical_name',
        value: 'Arroz Integral',
        hlc: hlc,
      );

      expect(col.key, equals('products:prod-001:canonical_name'));

      final json = col.toJson();
      final restored = ColumnVersion.fromJson(json);
      expect(restored, equals(col));
      expect(restored.hashCode, equals(col.hashCode));
      expect(col.toString(), contains('products:prod-001:canonical_name'));

      // Suporte camelCase em fromJson
      final restoredCamel = ColumnVersion.fromJson({
        'tableName': 'products',
        'rowId': 'prod-001',
        'columnName': 'canonical_name',
        'value': 'Arroz Integral',
        'hlc': hlc,
      });
      expect(restoredCamel, equals(col));

      // Support for sync_column_versions table keys (table_name, column_name)
      final restoredDbSchema = ColumnVersion.fromJson({
        'table_name': 'products',
        'row_id': 'prod-001',
        'column_name': 'canonical_name',
        'value': 'Arroz Integral',
        'hlc': hlc.pack(),
      });
      expect(restoredDbSchema, equals(col));
    });

    test(
      'CA-5.1: campos diferentes editados em A e B sao ambos preservados',
      () {
        // Dado o item "Leite" com quantidade 1 (estado inicial)
        final initialHlc = Hlc(millis: 1000, counter: 0, siteId: 'seed');
        final localByKey = {
          'shopping_items:item-milk:quantity_milli': initialHlc,
          'shopping_items:item-milk:is_bought': initialHlc,
        };

        // When A changes quantity to 2 (2000 milli)
        final hlcA = Hlc(millis: 1050, counter: 0, siteId: 'device-a');
        final versionA = ColumnVersion(
          table: 'shopping_items',
          rowId: 'item-milk',
          column: 'quantity_milli',
          value: 2000,
          hlc: hlcA,
        );

        // E B offline marca como comprado (is_bought = 1)
        final hlcB = Hlc(millis: 1060, counter: 0, siteId: 'device-b');
        final versionB = ColumnVersion(
          table: 'shopping_items',
          rowId: 'item-milk',
          column: 'is_bought',
          value: 1,
          hlc: hlcB,
        );

        // Aplicar versoes de A e B no estado inicial
        final winners = merge.winners([versionA, versionB], localByKey);

        // Ambos os campos venceram!
        expect(winners.length, equals(2));
        expect(
          winners.any((w) => w.column == 'quantity_milli' && w.value == 2000),
          isTrue,
        );
        expect(
          winners.any((w) => w.column == 'is_bought' && w.value == 1),
          isTrue,
        );
      },
    );

    test('RN-320: concurrent edits on same field resolved by highest HLC', () {
      final hlcLocal = Hlc(millis: 1000, counter: 0, siteId: 'dev-local');
      final localByKey = {'tasks:task-1:title': hlcLocal};

      // Versao recebida mais recente vence
      final hlcNewer = Hlc(millis: 2000, counter: 0, siteId: 'dev-remote');
      final vNewer = ColumnVersion(
        table: 'tasks',
        rowId: 'task-1',
        column: 'title',
        value: 'Lavar a louça hoje',
        hlc: hlcNewer,
      );

      final winners1 = merge.winners([vNewer], localByKey);
      expect(winners1, equals([vNewer]));

      // Versao recebida mais antiga perde
      final hlcOlder = Hlc(millis: 500, counter: 0, siteId: 'dev-remote');
      final vOlder = ColumnVersion(
        table: 'tasks',
        rowId: 'task-1',
        column: 'title',
        value: 'Lavar a louça ontem',
        hlc: hlcOlder,
      );

      final winners2 = merge.winners([vOlder], localByKey);
      expect(winners2, isEmpty);

      // Empate de millis e counter: desempate por siteId deterministico
      final hlcTieLower = Hlc(millis: 1000, counter: 0, siteId: 'aaa');
      final hlcTieHigher = Hlc(millis: 1000, counter: 0, siteId: 'zzz');

      final vTieLower = ColumnVersion(
        table: 'tasks',
        rowId: 'task-1',
        column: 'title',
        value: 'Título AAA',
        hlc: hlcTieLower,
      );
      final vTieHigher = ColumnVersion(
        table: 'tasks',
        rowId: 'task-1',
        column: 'title',
        value: 'Título ZZZ',
        hlc: hlcTieHigher,
      );

      // Se o local for 'aaa', 'zzz' vence
      final winners3 = merge.winners(
        [vTieHigher],
        {'tasks:task-1:title': hlcTieLower},
      );
      expect(winners3, equals([vTieHigher]));

      // Se o local for 'zzz', 'aaa' perde
      final winners4 = merge.winners(
        [vTieLower],
        {'tasks:task-1:title': hlcTieHigher},
      );
      expect(winners4, isEmpty);
    });

    test(
      'RN-322: exclusao (deleted_at) propaga e prevalece sobre edicao anterior',
      () {
        final hlcEdit = Hlc(millis: 1000, counter: 0, siteId: 'dev-1');
        final hlcDelete = Hlc(millis: 1100, counter: 0, siteId: 'dev-2');

        final vDelete = ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'deleted_at',
          value: '2026-10-22T12:00:00.000Z',
          hlc: hlcDelete,
        );

        final winners = merge.winners(
          [vDelete],
          {'expenses:exp-1:amount_cents': hlcEdit},
        );

        expect(winners, contains(vDelete));

        // Restaurar da lixeira (deleted_at = null com HLC posterior)
        final hlcRestore = Hlc(millis: 1200, counter: 0, siteId: 'dev-1');
        final vRestore = ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'deleted_at',
          value: null,
          hlc: hlcRestore,
        );

        final winnersRestore = merge.winners(
          [vRestore],
          {'expenses:exp-1:deleted_at': hlcDelete},
        );

        expect(winnersRestore, contains(vRestore));
      },
    );

    test('idempotency: applying same version multiple times produces no duplicate effect', () {
      final hlc = Hlc(millis: 2000, counter: 0, siteId: 'dev-1');
      final version = ColumnVersion(
        table: 'products',
        rowId: 'prod-1',
        column: 'canonical_name',
        value: 'Sabão em pó',
        hlc: hlc,
      );

      // 1ª aplicacao vence
      final winners1 = merge.winners([version], {});
      expect(winners1, equals([version]));

      // 2ª aplicacao com o estado local agora atualizado com o HLC da versao
      final localUpdated = {'products:prod-1:canonical_name': hlc};
      final winners2 = merge.winners([version], localUpdated);
      expect(winners2, isEmpty); // Nada para reaplicar
    });
  });
}
