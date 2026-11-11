import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db_pkg;
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/checklist_repository.dart';

class DriftChecklistRepository implements ChecklistRepository {
  final db_pkg.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  DriftChecklistRepository({
    required this.db,
    required this.clock,
    required this.idGenerator,
  });

  static const Map<String, List<String>> defaultPreset = {
    'Cozinha': [
      'Panelas e frigideiras',
      'Jogo de talheres',
      'Pratos e copos',
      'Potes para alimentos',
      'Esponja e detergente',
      'Panos de prato',
    ],
    'Banheiro': [
      'Toalhas de banho e rosto',
      'Papel higiênico',
      'Sabonete e shampoo',
      'Tapete de banheiro',
      'Escova sanitária e desentupidor',
    ],
    'Quarto': ['Jogo de lençol', 'Travesseiro e coberta', 'Cabides'],
    'Lavanderia': [
      'Vassoura e rodo',
      'Balde e bacia',
      'Panos de chão',
      'Sabão em pó e amaciante',
    ],
    'Sala': [
      'Lâmpadas de reserva',
      'Filtro de linha / extensão',
      'Sacos de lixo',
    ],
  };

  @override
  Future<Result<void, Failure>> seedDefaultsIfEmpty() async {
    try {
      final countExp = db.checklistItems.id.count();
      final query = db.selectOnly(db.checklistItems)..addColumns([countExp]);
      final count = await query.map((row) => row.read(countExp)).getSingle();

      if (count == 0) {
        final nowIso = clock.nowUtc().toIso8601String();
        await db.transaction(() async {
          int pos = 0;
          for (final entry in defaultPreset.entries) {
            final category = entry.key;
            for (final title in entry.value) {
              final id = idGenerator.newId();
              await db
                  .into(db.checklistItems)
                  .insert(
                    db_pkg.ChecklistItemsCompanion.insert(
                      id: id,
                      roomCategory: category,
                      title: title,
                      isMarked: const Value(false),
                      position: Value(pos++),
                      createdAt: Value(nowIso),
                      updatedAt: Value(nowIso),
                    ),
                  );
            }
          }
        });
      }
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao popular checklist padrão', cause: e),
      );
    }
  }

  @override
  Future<Result<List<ChecklistItem>, Failure>> getItems({
    String? roomCategory,
  }) async {
    try {
      await seedDefaultsIfEmpty();

      final query = db.select(db.checklistItems);
      if (roomCategory != null && roomCategory.isNotEmpty) {
        query.where((tbl) => tbl.roomCategory.equals(roomCategory));
      }
      query.orderBy([
        (tbl) => OrderingTerm(expression: tbl.position),
        (tbl) => OrderingTerm(expression: tbl.title),
      ]);

      final rows = await query.get();
      return Ok(rows.map(_mapToDomain).toList());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar itens do checklist', cause: e),
      );
    }
  }

  @override
  Future<Result<List<String>, Failure>> getRoomCategories() async {
    try {
      await seedDefaultsIfEmpty();

      final query = db.selectOnly(db.checklistItems, distinct: true)
        ..addColumns([db.checklistItems.roomCategory])
        ..orderBy([OrderingTerm(expression: db.checklistItems.roomCategory)]);
      final rows = await query.get();
      final categories = rows
          .map((r) => r.read(db.checklistItems.roomCategory))
          .whereType<String>()
          .toList();

      return Ok(categories);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar cômodos do checklist', cause: e),
      );
    }
  }

  @override
  Future<Result<ChecklistItem, Failure>> addItem({
    required String roomCategory,
    required String title,
  }) async {
    try {
      await seedDefaultsIfEmpty();

      final id = idGenerator.newId();
      final nowIso = clock.nowUtc().toIso8601String();

      final maxPosExp = db.checklistItems.position.max();
      final posQuery = db.selectOnly(db.checklistItems)
        ..addColumns([maxPosExp]);
      final maxPos =
          await posQuery.map((row) => row.read(maxPosExp)).getSingleOrNull() ??
          0;

      await db
          .into(db.checklistItems)
          .insert(
            db_pkg.ChecklistItemsCompanion.insert(
              id: id,
              roomCategory: roomCategory,
              title: title,
              isMarked: const Value(false),
              position: Value(maxPos + 1),
              createdAt: Value(nowIso),
              updatedAt: Value(nowIso),
            ),
          );

      final row = await (db.select(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      return Ok(_mapToDomain(row));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao adicionar item ao checklist', cause: e),
      );
    }
  }

  @override
  Future<Result<ChecklistItem, Failure>> toggleItemMarked(String id) async {
    try {
      await seedDefaultsIfEmpty();

      final existing = await (db.select(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

      if (existing == null) {
        return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
      }

      final newMarked = !existing.isMarked;
      final nowIso = clock.nowUtc().toIso8601String();

      await (db.update(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).write(
        db_pkg.ChecklistItemsCompanion(
          isMarked: Value(newMarked),
          updatedAt: Value(nowIso),
        ),
      );

      final updated = await (db.select(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      return Ok(_mapToDomain(updated));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao alternar estado do item', cause: e),
      );
    }
  }

  @override
  Future<Result<ChecklistItem, Failure>> updateItemTitle(
    String id,
    String newTitle,
  ) async {
    try {
      await seedDefaultsIfEmpty();

      final nowIso = clock.nowUtc().toIso8601String();

      final count =
          await (db.update(
            db.checklistItems,
          )..where((tbl) => tbl.id.equals(id))).write(
            db_pkg.ChecklistItemsCompanion(
              title: Value(newTitle),
              updatedAt: Value(nowIso),
            ),
          );

      if (count == 0) {
        return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
      }

      final updated = await (db.select(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      return Ok(_mapToDomain(updated));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao atualizar título do item', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteItem(String id) async {
    try {
      await seedDefaultsIfEmpty();

      final count = await (db.delete(
        db.checklistItems,
      )..where((tbl) => tbl.id.equals(id))).go();

      if (count == 0) {
        return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao remover item do checklist', cause: e),
      );
    }
  }

  ChecklistItem _mapToDomain(db_pkg.ChecklistItem row) {
    return ChecklistItem(
      id: row.id,
      roomCategory: row.roomCategory,
      title: row.title,
      isMarked: row.isMarked,
      position: row.position,
      createdAt: row.createdAt != null ? DateTime.parse(row.createdAt!) : null,
      updatedAt: row.updatedAt != null ? DateTime.parse(row.updatedAt!) : null,
    );
  }
}
