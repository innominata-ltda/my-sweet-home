import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/checklist_repository.dart';

class FakeChecklistRepository implements ChecklistRepository {
  final List<ChecklistItem> _items = [];
  int _nextId = 1;

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
    if (_items.isEmpty) {
      int pos = 0;
      for (final entry in defaultPreset.entries) {
        for (final title in entry.value) {
          _items.add(
            ChecklistItem(
              id: 'chk_${_nextId++}',
              roomCategory: entry.key,
              title: title,
              position: pos++,
              createdAt: DateTime.utc(2026),
            ),
          );
        }
      }
    }
    return const Ok(null);
  }

  @override
  Future<Result<List<ChecklistItem>, Failure>> getItems({
    String? roomCategory,
  }) async {
    await seedDefaultsIfEmpty();
    if (roomCategory != null && roomCategory.isNotEmpty) {
      final filtered = _items
          .where((i) => i.roomCategory == roomCategory)
          .toList();
      return Ok(List.unmodifiable(filtered));
    }
    return Ok(List.unmodifiable(_items));
  }

  @override
  Future<Result<List<String>, Failure>> getRoomCategories() async {
    await seedDefaultsIfEmpty();
    final categories = _items.map((i) => i.roomCategory).toSet().toList();
    return Ok(categories);
  }

  @override
  Future<Result<ChecklistItem, Failure>> addItem({
    required String roomCategory,
    required String title,
  }) async {
    await seedDefaultsIfEmpty();
    final newItem = ChecklistItem(
      id: 'chk_${_nextId++}',
      roomCategory: roomCategory,
      title: title,
      position: _items.length,
      createdAt: DateTime.utc(2026),
    );
    _items.add(newItem);
    return Ok(newItem);
  }

  @override
  Future<Result<ChecklistItem, Failure>> toggleItemMarked(String id) async {
    await seedDefaultsIfEmpty();
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
    }
    final current = _items[index];
    final updated = current.copyWith(
      isMarked: !current.isMarked,
      updatedAt: DateTime.utc(2026),
    );
    _items[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<ChecklistItem, Failure>> updateItemTitle(
    String id,
    String newTitle,
  ) async {
    await seedDefaultsIfEmpty();
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
    }
    final current = _items[index];
    final updated = current.copyWith(
      title: newTitle,
      updatedAt: DateTime.utc(2026),
    );
    _items[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void, Failure>> deleteItem(String id) async {
    await seedDefaultsIfEmpty();
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return Err(NotFoundFailure(what: 'ChecklistItem $id não encontrado'));
    }
    _items.removeAt(index);
    return const Ok(null);
  }
}
