import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide ChecklistItem, ShoppingList;
import 'package:my_sweet_home/features/extras/data/checklist_repository_provider.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_checklist_repository.dart';
import 'package:my_sweet_home/features/extras/data/repositories/fake_checklist_repository.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/extras/domain/usecases/convert_checklist_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_screen.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';
import '../shopping/domain/usecases/create_shopping_list_usecase_test.dart'
    show FakeShoppingListRepository;

void main() {
  group('ChecklistItem Domain Model', () {
    test('copyWith updates properties correctly', () {
      final item = ChecklistItem(
        id: '1',
        roomCategory: 'Cozinha',
        title: 'Panelas',
        isMarked: false,
        position: 0,
      );

      final updated = item.copyWith(isMarked: true, title: 'Panelas Inox');

      expect(updated.id, '1');
      expect(updated.roomCategory, 'Cozinha');
      expect(updated.title, 'Panelas Inox');
      expect(updated.isMarked, true);
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final item = ChecklistItem(
        id: '1',
        roomCategory: 'Banheiro',
        title: 'Toalhas',
        isMarked: true,
        position: 2,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = item.toJson();
      final restored = ChecklistItem.fromJson(json);

      expect(restored, equals(item));
    });
  });

  group('ConvertChecklistToShoppingListUseCase (RN-250, T-02)', () {
    late FakeShoppingListRepository shoppingRepo;
    late SequentialIdGenerator idGenerator;
    late FakeClock clock;
    late ConvertChecklistToShoppingListUseCase useCase;

    setUp(() {
      shoppingRepo = FakeShoppingListRepository();
      idGenerator = SequentialIdGenerator();
      clock = FakeClock(DateTime.utc(2026, 1, 1));
      useCase = ConvertChecklistToShoppingListUseCase(
        shoppingListRepository: shoppingRepo,
        idGenerator: idGenerator,
        clock: clock,
      );
    });

    test('converts unmarked checklist items to new shopping list with default name', () async {
      final items = [
        ChecklistItem(
          id: '1',
          roomCategory: 'Cozinha',
          title: 'Panelas',
          isMarked: false,
        ),
        ChecklistItem(
          id: '2',
          roomCategory: 'Cozinha',
          title: 'Pratos',
          isMarked: true,
        ),
        ChecklistItem(
          id: '3',
          roomCategory: 'Banheiro',
          title: 'Toalha de banho',
          isMarked: false,
        ),
      ];

      final result = await useCase(items: items);

      expect(result, isA<Ok<ShoppingList, Failure>>());
      final shoppingList = result.valueOrNull!;
      expect(shoppingList.name, equals('Lista da Casa (Checklist)'));
      expect(shoppingList.items.length, equals(2));
      expect(
        shoppingList.items.map((i) => i.parsedName),
        containsAll(['Panelas', 'Toalha de banho']),
      );
    });

    test('converts unmarked items with custom list name', () async {
      final items = [
        ChecklistItem(
          id: '1',
          roomCategory: 'Cozinha',
          title: 'Panelas',
          isMarked: false,
        ),
      ];

      final result = await useCase(items: items, listName: 'Lista de Mudança');

      expect(result, isA<Ok<ShoppingList, Failure>>());
      expect(result.valueOrNull!.name, equals('Lista de Mudança'));
    });

    test('appends unmarked items to existing shopping list', () async {
      final existingList = ShoppingList(
        id: 'list-existing',
        name: 'Mercado',
        createdAt: DateTime.utc(2026, 1, 1),
        items: [],
      );
      await shoppingRepo.save(existingList);

      final items = [
        ChecklistItem(
          id: '1',
          roomCategory: 'Cozinha',
          title: 'Sabão em pó',
          isMarked: false,
        ),
      ];

      final result = await useCase(items: items, targetListId: 'list-existing');

      expect(result, isA<Ok<ShoppingList, Failure>>());
      final updated = result.valueOrNull!;
      expect(updated.id, equals('list-existing'));
      expect(updated.items.length, equals(1));
      expect(updated.items.first.parsedName, equals('Sabão em pó'));
    });

    test('returns failure when no unmarked items are provided', () async {
      final items = [
        ChecklistItem(
          id: '1',
          roomCategory: 'Cozinha',
          title: 'Pratos',
          isMarked: true,
        ),
      ];

      final result = await useCase(items: items);

      expect(result, isA<Err<ShoppingList, Failure>>());
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('FakeChecklistRepository (RN-250, CA-1.1)', () {
    late FakeChecklistRepository repo;

    setUp(() {
      repo = FakeChecklistRepository();
    });

    test('seeds default items by room category when empty', () async {
      final itemsResult = await repo.getItems();
      expect(itemsResult, isA<Ok<List<ChecklistItem>, Failure>>());

      final items = itemsResult.valueOrNull!;
      expect(items.isNotEmpty, isTrue);

      final categoriesResult = await repo.getRoomCategories();
      final categories = categoriesResult.valueOrNull!;
      expect(
        categories,
        containsAll(['Cozinha', 'Banheiro', 'Quarto', 'Lavanderia', 'Sala']),
      );
    });

    test('CA-1.1: marking 5 items updates progress correctly', () async {
      final items = (await repo.getItems()).valueOrNull!;
      expect(items.length, greaterThanOrEqualTo(5));

      for (int i = 0; i < 5; i++) {
        await repo.toggleItemMarked(items[i].id);
      }

      final updatedItems = (await repo.getItems()).valueOrNull!;
      final markedCount = updatedItems.where((item) => item.isMarked).length;
      expect(markedCount, 5);
    });

    test('allows adding custom items', () async {
      final addResult = await repo.addItem(
        roomCategory: 'Cozinha',
        title: 'Air Fryer',
      );
      expect(addResult, isA<Ok<ChecklistItem, Failure>>());
      final newItem = addResult.valueOrNull!;
      expect(newItem.title, 'Air Fryer');
      expect(newItem.roomCategory, 'Cozinha');

      final cozinhaItems = (await repo.getItems(roomCategory: 'Cozinha'))
          .valueOrNull!;
      expect(cozinhaItems.map((i) => i.title), contains('Air Fryer'));
    });

    test('allows updating item title', () async {
      final items = (await repo.getItems()).valueOrNull!;
      final target = items.first;

      final updateResult = await repo.updateItemTitle(
        target.id,
        'Título Editado',
      );
      expect(updateResult, isA<Ok<ChecklistItem, Failure>>());

      final updated = updateResult.valueOrNull!;
      expect(updated.title, 'Título Editado');
    });

    test('allows deleting an item', () async {
      final items = (await repo.getItems()).valueOrNull!;
      final target = items.first;

      final deleteResult = await repo.deleteItem(target.id);
      expect(deleteResult, isA<Ok<void, Failure>>());

      final newItems = (await repo.getItems()).valueOrNull!;
      expect(newItems.any((i) => i.id == target.id), isFalse);
    });

    test(
      'calling addItem on unseeded repository seeds defaults first',
      () async {
        final unseededRepo = FakeChecklistRepository();
        await unseededRepo.addItem(roomCategory: 'Varanda', title: 'Rede');

        final items = (await unseededRepo.getItems()).valueOrNull!;
        expect(items.length, greaterThan(5));
        expect(items.any((i) => i.title == 'Rede'), isTrue);
      },
    );
  });

  group('DriftChecklistRepository (Database Integration)', () {
    late AppDatabase db;
    late DriftChecklistRepository repo;
    late FakeClock clock;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 1, 1));
      repo = DriftChecklistRepository(
        db: db,
        clock: clock,
        idGenerator: SequentialIdGenerator(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'calling addItem on fresh empty database seeds defaults first',
      () async {
        await repo.addItem(
          roomCategory: 'Varanda',
          title: 'Cadeira de Balanço',
        );
        final items = (await repo.getItems()).valueOrNull!;
        expect(items.length, greaterThan(5));
        expect(items.any((i) => i.title == 'Cadeira de Balanço'), isTrue);
      },
    );

    test('seeds default preset into database on first fetch', () async {
      final itemsResult = await repo.getItems();
      expect(itemsResult, isA<Ok<List<ChecklistItem>, Failure>>());

      final items = itemsResult.valueOrNull!;
      expect(items.length, greaterThan(10));
    });

    test('persists item toggle state', () async {
      final items = (await repo.getItems()).valueOrNull!;
      final first = items.first;

      await repo.toggleItemMarked(first.id);

      final reloaded = (await repo.getItems()).valueOrNull!;
      final updated = reloaded.firstWhere((i) => i.id == first.id);
      expect(updated.isMarked, isTrue);
    });

    test('persists item deletion', () async {
      final items = (await repo.getItems()).valueOrNull!;
      final first = items.first;

      await repo.deleteItem(first.id);

      final reloaded = (await repo.getItems()).valueOrNull!;
      expect(reloaded.any((i) => i.id == first.id), isFalse);
    });

    test('addItem creates and persists new item', () async {
      final result = await repo.addItem(
        roomCategory: 'Varanda',
        title: 'Cadeira de praia',
      );
      expect(result, isA<Ok<ChecklistItem, Failure>>());

      final items = (await repo.getItems(roomCategory: 'Varanda')).valueOrNull!;
      expect(items.any((i) => i.title == 'Cadeira de praia'), isTrue);
    });

    test('updateItemTitle modifies title in database', () async {
      final items = (await repo.getItems()).valueOrNull!;
      final target = items.first;

      final result = await repo.updateItemTitle(target.id, 'Novo Título');
      expect(result, isA<Ok<ChecklistItem, Failure>>());
      expect(result.valueOrNull!.title, 'Novo Título');

      final reloaded = (await repo.getItems()).valueOrNull!;
      final updated = reloaded.firstWhere((i) => i.id == target.id);
      expect(updated.title, 'Novo Título');
    });

    test('getRoomCategories returns all room categories sorted', () async {
      final categoriesResult = await repo.getRoomCategories();
      expect(categoriesResult, isA<Ok<List<String>, Failure>>());
      final categories = categoriesResult.valueOrNull!;
      expect(
        categories,
        containsAll(['Cozinha', 'Banheiro', 'Quarto', 'Lavanderia', 'Sala']),
      );
    });

    test('returns NotFoundFailure when modifying non-existent item', () async {
      final toggleRes = await repo.toggleItemMarked('non-existent-id');
      expect(toggleRes, isA<Err<ChecklistItem, Failure>>());

      final updateRes = await repo.updateItemTitle(
        'non-existent-id',
        'Updated',
      );
      expect(updateRes, isA<Err<ChecklistItem, Failure>>());

      final deleteRes = await repo.deleteItem('non-existent-id');
      expect(deleteRes, isA<Err<void, Failure>>());
    });
  });

  group('ChecklistScreen Widget Tests', () {
    late FakeChecklistRepository fakeRepo;
    late FakeShoppingListRepository fakeShoppingRepo;

    setUp(() {
      fakeRepo = FakeChecklistRepository();
      fakeShoppingRepo = FakeShoppingListRepository();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          checklistRepositoryProvider.overrideWithValue(fakeRepo),
          shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
        ],
        child: const MaterialApp(home: ChecklistScreen()),
      );
    }

    testWidgets('renders pre-loaded checklist items and progress card', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Checklist da casa'), findsOneWidget);
      expect(find.text('Progresso da casa'), findsOneWidget);

      expect(find.text('Todos'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cozinha'), findsOneWidget);

      expect(find.text('Panelas e frigideiras'), findsOneWidget);
    });

    testWidgets('toggling item checkbox updates state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox).first;
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final items = (await fakeRepo.getItems()).valueOrNull!;
      expect(items.first.isMarked, isTrue);
    });

    testWidgets('filtering by room category works', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Banheiro'));
      await tester.pumpAndSettle();

      expect(find.text('Toalhas de banho e rosto'), findsOneWidget);
      expect(find.text('Panelas e frigideiras'), findsNothing);
    });

    testWidgets(
      'adding a new item via dialog pre-fills active category filter',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilterChip, 'Banheiro'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Novo item'));
        await tester.pumpAndSettle();

        final categoryInput = tester.widget<TextField>(
          find.byKey(const Key('add_item_category_input')),
        );
        expect(categoryInput.controller?.text, equals('Banheiro'));

        await tester.enterText(
          find.byKey(const Key('add_item_title_input')),
          'Sabonete Líquido',
        );
        await tester.tap(find.byKey(const Key('confirm_add_item_button')));
        await tester.pumpAndSettle();

        expect(find.text('Sabonete Líquido'), findsOneWidget);
      },
    );

    testWidgets('editing item title via dialog works', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final items = (await fakeRepo.getItems()).valueOrNull!;
      final firstItem = items.first;

      await tester.tap(find.byKey(Key('edit_${firstItem.id}')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_item_title_input')),
        'Panelas de Inox',
      );
      await tester.tap(find.byKey(const Key('confirm_edit_item_button')));
      await tester.pumpAndSettle();

      expect(find.text('Panelas de Inox'), findsOneWidget);
    });

    testWidgets('deleting item via dialog works', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final items = (await fakeRepo.getItems()).valueOrNull!;
      final firstItem = items.first;

      await tester.tap(find.byKey(Key('delete_${firstItem.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_delete_item_button')));
      await tester.pumpAndSettle();

      expect(find.text(firstItem.title), findsNothing);
    });

    testWidgets(
      'T-02 / RN-250: exporting unmarked checklist items creates shopping list via dialog',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap export button on progress card
        final exportButton = find.byKey(
          const Key('export_unmarked_card_button'),
        );
        expect(exportButton, findsOneWidget);
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Dialog opens
        expect(find.text('Gerar lista de compras'), findsOneWidget);
        expect(
          find.byKey(const Key('shopping_list_name_input')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('shopping_list_name_input')),
          'Minha Lista',
        );
        await tester.tap(
          find.byKey(const Key('confirm_export_shopping_list_button')),
        );
        await tester.pumpAndSettle();

        // Verify shopping list was created in repository
        final lists = (await fakeShoppingRepo.getAll()).valueOrNull!;
        expect(lists.length, equals(1));
        expect(lists.first.name, equals('Minha Lista'));
        expect(lists.first.items.isNotEmpty, isTrue);
      },
    );
  });
}
