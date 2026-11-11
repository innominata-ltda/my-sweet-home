import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_bundle.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

import '../../fakes/fake_file_store.dart';

void main() {
  group('T-01 — SPEC-010 Backup & Export Test Suite', () {
    late AppDatabase db;
    late FakeFileStore fakeFileStore;
    late DriftBackupService backupService;

    setUp(() {
      db = AppDatabase.memory();
      fakeFileStore = FakeFileStore();
      backupService = DriftBackupService(db, fileStore: fakeFileStore);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> populateFullDatabase(AppDatabase targetDb) async {
      await targetDb.customStatement('PRAGMA foreign_keys = OFF;');
      try {
        // 1. Categories
        await targetDb
            .into(targetDb.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat_alimentacao',
                name: 'Alimentação',
                kind: 'expense',
                iconKey: 'restaurant',
              ),
            );

        // 2. Products
        await targetDb
            .into(targetDb.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod_leite',
                canonicalName: 'Leite Integral 1L',
                defaultUnit: 'l',
                categoryId: const Value('cat_alimentacao'),
              ),
            );

        // 3. Product Aliases
        await targetDb
            .into(targetDb.productAliases)
            .insert(
              ProductAliasesCompanion.insert(
                id: 'alias_leite_1',
                productId: 'prod_leite',
                alias: 'Leite Int 1L',
                normalizedAlias: 'leite int 1l',
                source: 'ocr',
              ),
            );

        // 4. Stores
        await targetDb
            .into(targetDb.stores)
            .insert(
              StoresCompanion.insert(
                id: 'store_super',
                name: 'Supermercado Central',
                cnpj: const Value('12.345.678/0001-90'),
              ),
            );

        // 5. Purchases & Items
        await targetDb
            .into(targetDb.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: 'purchase_1',
                storeId: const Value('store_super'),
                purchasedAt: '2026-09-15',
                totalCents: 4550,
                discountCents: const Value(500),
                paymentMethod: const Value('cartao_credito'),
                source: 'manual',
                expenseId: const Value('exp_almoço'),
              ),
            );

        await targetDb
            .into(targetDb.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: 'pitem_1',
                purchaseId: 'purchase_1',
                productId: const Value('prod_leite'),
                rawDescription: 'Leite Integral 1L',
                quantityMilli: 2000,
                unit: 'l',
                unitPriceCents: 500,
                totalPriceCents: 1000,
                position: 0,
              ),
            );

        // 6. Expenses
        await targetDb
            .into(targetDb.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'exp_almoço',
                amountCents: 3250,
                occurredOn: '2026-09-16',
                description: const Value('Almoço de negócios'),
                categoryId: const Value('cat_alimentacao'),
                purchaseId: const Value('purchase_1'),
                billId: const Value('bill_luz'),
              ),
            );

        // 7. Bills & BillPayments
        await targetDb
            .into(targetDb.bills)
            .insert(
              BillsCompanion.insert(
                id: 'bill_luz',
                title: 'Conta de Luz',
                amountCents: const Value(15000),
                isAmountVariable: false,
                dueDay: 10,
              ),
            );

        await targetDb
            .into(targetDb.billPayments)
            .insert(
              BillPaymentsCompanion.insert(
                id: 'payment_luz_1',
                billId: const Value('bill_luz'),
                dueOn: '2026-10-10',
                status: 'pending',
                expenseId: const Value('exp_almoço'),
              ),
            );

        // 8. Shopping Lists & Items
        await targetDb
            .into(targetDb.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(
                id: 'list_semanal',
                name: 'Compras da Semana',
              ),
            );

        await targetDb
            .into(targetDb.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                id: 'sitem_1',
                listId: const Value('list_semanal'),
                productId: const Value('prod_leite'),
                quantityMilli: const Value(3000),
                unit: const Value('l'),
                source: 'manual',
                position: 0,
              ),
            );

        // 9. Tasks
        await targetDb
            .into(targetDb.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task_limpeza',
                title: 'Limpar a cozinha',
              ),
            );

        // 10. Recipes & Ingredients & Tags
        await targetDb
            .into(targetDb.recipes)
            .insert(
              RecipesCompanion.insert(id: 'recipe_bolo', title: 'Bolo de Fubá'),
            );

        await targetDb
            .into(targetDb.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion.insert(
                id: 'ring_1',
                recipeId: const Value('recipe_bolo'),
                rawText: '2 xícaras de fubá',
                position: 0,
              ),
            );

        await targetDb
            .into(targetDb.recipeTags)
            .insert(
              RecipeTagsCompanion.insert(
                recipeId: 'recipe_bolo',
                tag: 'café da tarde',
              ),
            );

        // 11. Stock & Checklist
        await targetDb
            .into(targetDb.stockItems)
            .insert(
              StockItemsCompanion.insert(
                id: 'stock_leite',
                productId: 'prod_leite',
                quantityMilli: const Value(2000),
              ),
            );

        await targetDb
            .into(targetDb.checklistItems)
            .insert(
              ChecklistItemsCompanion.insert(
                id: 'check_toalha',
                roomCategory: 'Banheiro',
                title: 'Trocar toalhas',
              ),
            );

        // 12. Product Denials
        await targetDb
            .into(targetDb.productDenials)
            .insert(
              ProductDenialsCompanion.insert(
                id: 'denial_1',
                productId: 'prod_leite',
                rawText: 'Leite Condensado',
                normalizedText: 'leite condensado',
              ),
            );

        // 13. Recurring Rules
        await targetDb
            .into(targetDb.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: 'rec_rule_1',
                kind: 'expense',
                rrule: 'FREQ=MONTHLY',
                startsOn: '2026-01-01',
                amountCents: const Value(12000),
                title: 'Assinatura Internet',
              ),
            );

        // 14. Budgets
        await targetDb
            .into(targetDb.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'budget_1',
                yearMonth: '2026-09',
                categoryId: const Value('cat_alimentacao'),
                limitCents: 50000,
              ),
            );

        // 15. Price Points
        await targetDb
            .into(targetDb.pricePoints)
            .insert(
              PricePointsCompanion.insert(
                id: 'pp_1',
                productId: const Value('prod_leite'),
                storeId: const Value('store_super'),
                observedAt: '2026-09-15',
                unitPriceCents: 500,
                normalizedPriceCents: 500,
                quantityMilli: 1000,
                unit: 'l',
                source: 'manual',
              ),
            );

        // 16. Attachments
        await targetDb
            .into(targetDb.attachments)
            .insert(
              AttachmentsCompanion.insert(
                id: 'attach_1',
                path: '/storage/receipt_1.jpg',
                kind: const Value('receipt'),
                ownerType: const Value('purchase'),
                ownerId: const Value('purchase_1'),
              ),
            );

        // 17. Settings & Consents
        await targetDb
            .into(targetDb.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'delete_receipt_photo',
                value: 'true',
              ),
            );

        await targetDb
            .into(targetDb.consents)
            .insert(ConsentsCompanion.insert(key: 'cloud_ocr', granted: false));
      } finally {
        await targetDb.customStatement('PRAGMA foreign_keys = ON;');
      }
    }

    test('CA-1.1 — Exports full database to JSON + CSV and reimports identically', () async {
      await populateFullDatabase(db);

      // Initial sums of all tables with monetary values
      final expSumBefore = await db
          .customSelect('SELECT SUM(amount_cents) as total FROM expenses')
          .getSingle();
      final purSumBefore = await db
          .customSelect('SELECT SUM(total_cents) as total FROM purchases')
          .getSingle();
      final purDiscSumBefore = await db
          .customSelect('SELECT SUM(discount_cents) as total FROM purchases')
          .getSingle();
      final pitemSumBefore = await db
          .customSelect(
            'SELECT SUM(total_price_cents) as total FROM purchase_items',
          )
          .getSingle();
      final budgetSumBefore = await db
          .customSelect('SELECT SUM(limit_cents) as total FROM budgets')
          .getSingle();
      final recSumBefore = await db
          .customSelect(
            'SELECT SUM(amount_cents) as total FROM recurring_rules',
          )
          .getSingle();
      final pricePointSumBefore = await db
          .customSelect(
            'SELECT SUM(unit_price_cents) as total FROM price_points',
          )
          .getSingle();
      final billSumBefore = await db
          .customSelect('SELECT SUM(amount_cents) as total FROM bills')
          .getSingle();

      final expTotalBefore = expSumBefore.read<int>('total');
      final purTotalBefore = purSumBefore.read<int>('total');
      final purDiscTotalBefore = purDiscSumBefore.read<int>('total');
      final pitemTotalBefore = pitemSumBefore.read<int>('total');
      final budgetTotalBefore = budgetSumBefore.read<int>('total');
      final recTotalBefore = recSumBefore.read<int>('total');
      final pricePointTotalBefore = pricePointSumBefore.read<int>('total');
      final billTotalBefore = billSumBefore.read<int>('total');

      final exportRes = await backupService.exportBackup();
      expect(exportRes.isOk, isTrue);
      final bundle = exportRes.valueOrNull!;

      expect(bundle.schemaVersion, equals(db.schemaVersion));
      expect(bundle.tables['products']?.length, equals(1));
      expect(bundle.tables['expenses']?.length, equals(1));
      expect(bundle.tables['purchases']?.length, equals(1));
      expect(bundle.tables['bills']?.length, equals(1));
      expect(bundle.tables['budgets']?.length, equals(1));
      expect(bundle.tables['recurring_rules']?.length, equals(1));
      expect(bundle.tables['price_points']?.length, equals(1));
      expect(bundle.tables['product_denials']?.length, equals(1));
      expect(bundle.tables['attachments']?.length, equals(1));
      expect(bundle.csv['expenses'], contains('Almoço de negócios'));
      expect(bundle.csv['purchases'], contains('Supermercado Central'));

      final jsonString = bundle.toJsonString();

      // Creates a second clean in-memory database
      final cleanDb = AppDatabase.memory();
      final cleanService = DriftBackupService(cleanDb);

      try {
        final importRes = await cleanService.importBackup(jsonString);
        expect(importRes.isOk, isTrue);

        // Verifica se todas as contagens batem exatamente (todas as 24 tabelas)
        expect(
          await cleanDb.categories.count().getSingle(),
          equals(await db.categories.count().getSingle()),
        );
        expect(
          await cleanDb.products.count().getSingle(),
          equals(await db.products.count().getSingle()),
        );
        expect(
          await cleanDb.productAliases.count().getSingle(),
          equals(await db.productAliases.count().getSingle()),
        );
        expect(
          await cleanDb.productDenials.count().getSingle(),
          equals(await db.productDenials.count().getSingle()),
        );
        expect(
          await cleanDb.stores.count().getSingle(),
          equals(await db.stores.count().getSingle()),
        );
        expect(
          await cleanDb.purchases.count().getSingle(),
          equals(await db.purchases.count().getSingle()),
        );
        expect(
          await cleanDb.purchaseItems.count().getSingle(),
          equals(await db.purchaseItems.count().getSingle()),
        );
        expect(
          await cleanDb.pricePoints.count().getSingle(),
          equals(await db.pricePoints.count().getSingle()),
        );
        expect(
          await cleanDb.expenses.count().getSingle(),
          equals(await db.expenses.count().getSingle()),
        );
        expect(
          await cleanDb.budgets.count().getSingle(),
          equals(await db.budgets.count().getSingle()),
        );
        expect(
          await cleanDb.recurringRules.count().getSingle(),
          equals(await db.recurringRules.count().getSingle()),
        );
        expect(
          await cleanDb.bills.count().getSingle(),
          equals(await db.bills.count().getSingle()),
        );
        expect(
          await cleanDb.billPayments.count().getSingle(),
          equals(await db.billPayments.count().getSingle()),
        );
        expect(
          await cleanDb.shoppingLists.count().getSingle(),
          equals(await db.shoppingLists.count().getSingle()),
        );
        expect(
          await cleanDb.shoppingItems.count().getSingle(),
          equals(await db.shoppingItems.count().getSingle()),
        );
        expect(
          await cleanDb.tasks.count().getSingle(),
          equals(await db.tasks.count().getSingle()),
        );
        expect(
          await cleanDb.recipes.count().getSingle(),
          equals(await db.recipes.count().getSingle()),
        );
        expect(
          await cleanDb.recipeIngredients.count().getSingle(),
          equals(await db.recipeIngredients.count().getSingle()),
        );
        expect(
          await cleanDb.recipeTags.count().getSingle(),
          equals(await db.recipeTags.count().getSingle()),
        );
        expect(
          await cleanDb.stockItems.count().getSingle(),
          equals(await db.stockItems.count().getSingle()),
        );
        expect(
          await cleanDb.checklistItems.count().getSingle(),
          equals(await db.checklistItems.count().getSingle()),
        );
        expect(
          await cleanDb.settings.count().getSingle(),
          equals(await db.settings.count().getSingle()),
        );
        expect(
          await cleanDb.consents.count().getSingle(),
          equals(await db.consents.count().getSingle()),
        );
        expect(
          await cleanDb.attachments.count().getSingle(),
          equals(await db.attachments.count().getSingle()),
        );

        // Identical monetary sums
        final expSumAfter = await cleanDb
            .customSelect('SELECT SUM(amount_cents) as total FROM expenses')
            .getSingle();
        final purSumAfter = await cleanDb
            .customSelect('SELECT SUM(total_cents) as total FROM purchases')
            .getSingle();
        final purDiscSumAfter = await cleanDb
            .customSelect('SELECT SUM(discount_cents) as total FROM purchases')
            .getSingle();
        final pitemSumAfter = await cleanDb
            .customSelect(
              'SELECT SUM(total_price_cents) as total FROM purchase_items',
            )
            .getSingle();
        final budgetSumAfter = await cleanDb
            .customSelect('SELECT SUM(limit_cents) as total FROM budgets')
            .getSingle();
        final recSumAfter = await cleanDb
            .customSelect(
              'SELECT SUM(amount_cents) as total FROM recurring_rules',
            )
            .getSingle();
        final pricePointSumAfter = await cleanDb
            .customSelect(
              'SELECT SUM(unit_price_cents) as total FROM price_points',
            )
            .getSingle();
        final billSumAfter = await cleanDb
            .customSelect('SELECT SUM(amount_cents) as total FROM bills')
            .getSingle();

        expect(expSumAfter.read<int>('total'), equals(expTotalBefore));
        expect(purSumAfter.read<int>('total'), equals(purTotalBefore));
        expect(purDiscSumAfter.read<int>('total'), equals(purDiscTotalBefore));
        expect(pitemSumAfter.read<int>('total'), equals(pitemTotalBefore));
        expect(budgetSumAfter.read<int>('total'), equals(budgetTotalBefore));
        expect(recSumAfter.read<int>('total'), equals(recTotalBefore));
        expect(
          pricePointSumAfter.read<int>('total'),
          equals(pricePointTotalBefore),
        );
        expect(billSumAfter.read<int>('total'), equals(billTotalBefore));
      } finally {
        await cleanDb.close();
      }
    });

    test('CA-1.2 — Rejects future schema version import with explanatory message without corruption', () async {
      await populateFullDatabase(db);
      final countBefore = await db.expenses.count().getSingle();

      final futureTables = {
        'expenses': [
          {
            'id': 'future_exp',
            'amount_cents': 99999,
            'occurred_on': '2030-01-01',
          },
        ],
      };
      final futureBundle = BackupBundle(
        schemaVersion: 99,
        exportedAt: DateTime.now().toIso8601String(),
        tables: futureTables,
        csv: {},
        checksum: await BackupBundle.computeChecksum(futureTables),
      );

      final importRes = await backupService.importBackup(
        futureBundle.toJsonString(),
      );
      expect(importRes.isErr, isTrue);

      final failure = importRes.failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).detail, contains('é mais recente'));

      // Banco original permaneceu intocado
      final countAfter = await db.expenses.count().getSingle();
      expect(countAfter, equals(countBefore));
    });

    test(
      'RN-238 — Exclui tokens, senhas e chaves das configurações exportadas',
      () async {
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'delete_receipt_photo',
                value: 'true',
              ),
            );
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'auth_token',
                value: 'secret_jwt_token_12345',
              ),
            );
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'user_password_hash',
                value: 'argon2id_secret_hash',
              ),
            );

        await db
            .into(db.settings)
            .insert(SettingsCompanion.insert(key: 'user_pin', value: '1234'));
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'encryption_key',
                value: 'super_secret_aes_key',
              ),
            );

        final exportRes = await backupService.exportBackup();
        expect(exportRes.isOk, isTrue);
        final bundle = exportRes.valueOrNull!;

        final settingsTable = bundle.tables['settings'] ?? [];
        expect(
          settingsTable.any((row) => row['key'] == 'delete_receipt_photo'),
          isTrue,
        );
        expect(settingsTable.any((row) => row['key'] == 'auth_token'), isFalse);
        expect(
          settingsTable.any((row) => row['key'] == 'user_password_hash'),
          isFalse,
        );
        expect(settingsTable.any((row) => row['key'] == 'user_pin'), isFalse);
        expect(
          settingsTable.any((row) => row['key'] == 'encryption_key'),
          isFalse,
        );

        final jsonOutput = bundle.toJsonString();
        expect(jsonOutput, isNot(contains('secret_jwt_token_12345')));
        expect(jsonOutput, isNot(contains('argon2id_secret_hash')));
        expect(jsonOutput, isNot(contains('super_secret_aes_key')));
      },
    );

    group('T-V2 — Nenhum token, senha ou chave no arquivo exportado (RN-238)', () {
      test('Exhaustively removes all variations of tokens, passwords, keys, PINs, hashes, and secrets from settings and consents tables', () async {
        final sensitiveEntries = {
          'auth_token': 'bearer_token_abc123',
          'access_token': 'acc_token_xyz987',
          'refresh_token': 'ref_token_456789',
          'jwt_secret': 'super_secret_jwt_key',
          'user_password_hash': 'argon2id_hash_val',
          'user_pin': '9876',
          'encryption_key': 'aes_256_key_val',
          'api_key': 'google_api_key_123',
          'private_key': 'rsa_private_key_content',
          'master_key': 'master_db_key',
          'session_id': 'session_token_def456',
          'bearer_token': 'bearer_xyz',
          'oauth_credential': 'oauth_secret_data',
          'pin_code': '4321',
          'hash_salt': 'random_salt_bytes',
        };

        for (final entry in sensitiveEntries.entries) {
          await db
              .into(db.settings)
              .insert(
                SettingsCompanion.insert(key: entry.key, value: entry.value),
              );
        }

        // Legitimate settings with words containing partial substrings of "pass" or "key" (false positives)
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(key: 'compass_mode', value: 'enabled'),
            );
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'keyboard_vibration',
                value: 'true',
              ),
            );
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(key: 'bypass_warning', value: 'false'),
            );

        // Legitimate settings (non-sensitive)
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'delete_receipt_photo',
                value: 'true',
              ),
            );
        await db
            .into(db.settings)
            .insert(SettingsCompanion.insert(key: 'theme_mode', value: 'dark'));
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(key: 'currency_code', value: 'BRL'),
            );

        // Setting com chave neutra mas valor contendo token Bearer/JWT
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'legacy_setting',
                value:
                    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.signature',
              ),
            );

        // Consents: legitimate consent vs consent containing auth/token keyword
        await db
            .into(db.consents)
            .insert(ConsentsCompanion.insert(key: 'cloud_ocr', granted: true));
        await db
            .into(db.consents)
            .insert(
              ConsentsCompanion.insert(key: 'cloud_backup', granted: false),
            );

        final exportRes = await backupService.exportBackup();
        expect(exportRes.isOk, isTrue);
        final bundle = exportRes.valueOrNull!;

        final settingsTable = bundle.tables['settings'] ?? [];
        final settingsKeys = settingsTable
            .map((r) => r['key'] as String)
            .toSet();

        // Ensure legitimate keys remained (avoiding false positives)
        expect(settingsKeys, contains('delete_receipt_photo'));
        expect(settingsKeys, contains('theme_mode'));
        expect(settingsKeys, contains('currency_code'));
        expect(settingsKeys, contains('compass_mode'));
        expect(settingsKeys, contains('keyboard_vibration'));
        expect(settingsKeys, contains('bypass_warning'));

        // Garante que a chave com valor de token Bearer/JWT foi removida
        expect(settingsKeys, isNot(contains('legacy_setting')));

        // Ensure NO sensitive key was exported
        for (final sensitiveKey in sensitiveEntries.keys) {
          expect(
            settingsKeys,
            isNot(contains(sensitiveKey)),
            reason:
                'A chave sensível $sensitiveKey não deveria estar presente no export',
          );
        }

        // Ensure NO sensitive value leaked in serialized JSON
        final jsonOutput = bundle.toJsonString();
        for (final sensitiveValue in sensitiveEntries.values) {
          expect(
            jsonOutput,
            isNot(contains(sensitiveValue)),
            reason: 'Sensitive value $sensitiveValue leaked in exported JSON',
          );
        }

        // Valida que consents foram preservados corretamente
        final consentsTable = bundle.tables['consents'] ?? [];
        final consentKeys = consentsTable
            .map((r) => r['key'] as String)
            .toSet();
        expect(consentKeys, contains('cloud_ocr'));
        expect(consentKeys, contains('cloud_backup'));
      });

      test('isSensitiveSettingKey identifies sensitive terms by token and prevents false positives', () {
        // Sensitive (must return true)
        expect(DriftBackupService.isSensitiveSettingKey('auth_token'), isTrue);
        expect(
          DriftBackupService.isSensitiveSettingKey('userPasswordHash'),
          isTrue,
        );
        expect(DriftBackupService.isSensitiveSettingKey('jwt_secret'), isTrue);
        expect(DriftBackupService.isSensitiveSettingKey('user_pin'), isTrue);
        expect(
          DriftBackupService.isSensitiveSettingKey('encryption_key'),
          isTrue,
        );
        expect(DriftBackupService.isSensitiveSettingKey('user_pwd'), isTrue);
        expect(DriftBackupService.isSensitiveSettingKey('pass_code'), isTrue);
        expect(DriftBackupService.isSensitiveSettingKey('api_key'), isTrue);

        // Non-sensitive (must return false)
        expect(
          DriftBackupService.isSensitiveSettingKey('compass_mode'),
          isFalse,
        );
        expect(
          DriftBackupService.isSensitiveSettingKey('keyboard_vibration'),
          isFalse,
        );
        expect(
          DriftBackupService.isSensitiveSettingKey('bypass_warning'),
          isFalse,
        );
        expect(
          DriftBackupService.isSensitiveSettingKey('delete_receipt_photo'),
          isFalse,
        );
        expect(DriftBackupService.isSensitiveSettingKey('theme_mode'), isFalse);
        expect(
          DriftBackupService.isSensitiveSettingKey('currency_code'),
          isFalse,
        );
      });
    });

    test('RN-230 — Exports expense and purchase CSVs with UTF-8, ; and comma decimal separator escaping special characters', () async {
      await populateFullDatabase(db);
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_complex',
              name: 'Lazer; Cinema & "Show"',
              kind: 'expense',
              iconKey: 'movie',
            ),
          );
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'exp_cinema',
              amountCents: 5000,
              occurredOn: '2026-09-20',
              description: const Value('Ingresso "VIP"; Pipoca'),
              categoryId: const Value('cat_complex'),
            ),
          );

      final expCsvRes = await backupService.exportExpensesCsv();
      expect(expCsvRes.isOk, isTrue);
      final expCsv = expCsvRes.valueOrNull!;

      expect(expCsv, contains('\uFEFF')); // BOM UTF-8
      expect(expCsv, contains('Data;Descrição;Categoria;Valor'));
      expect(
        expCsv,
        contains('16/09/2026;Almoço de negócios;Alimentação;32,50'),
      );
      expect(
        expCsv,
        contains(
          '20/09/2026;"Ingresso ""VIP""; Pipoca";"Lazer; Cinema & ""Show""";50,00',
        ),
      );

      final purCsvRes = await backupService.exportPurchasesCsv();
      expect(purCsvRes.isOk, isTrue);
      final purCsv = purCsvRes.valueOrNull!;

      expect(
        purCsv,
        contains('Data;Estabelecimento;CNPJ;Total;Desconto;Forma de Pagamento'),
      );
      expect(
        purCsv,
        contains(
          '15/09/2026;Supermercado Central;12.345.678/0001-90;45,50;5,00;cartao_credito',
        ),
      );
    });

    test('RN-231 / Edge Case — Rejects backup with malformed JSON or invalid schema version (< 1)', () async {
      final badJsonRes = await backupService.importBackup('{ invalid json');
      expect(badJsonRes.isErr, isTrue);
      expect(badJsonRes.failureOrNull, isA<ValidationFailure>());

      final zeroVersionJson =
          '{"schema_version": 0, "exported_at": "2026-09-22", "tables": {}}';
      final zeroRes = await backupService.importBackup(zeroVersionJson);
      expect(zeroRes.isErr, isTrue);
      expect(zeroRes.failureOrNull, isA<ValidationFailure>());
    });

    group(
      'T-03 — RN-232 Import com Pré-visualização, Substituir e Mesclar',
      () {
        test('previewBackup calcula contagens por tabela e registros totais sem alterar o banco', () async {
          final tables = {
            'categories': [
              {
                'id': 'cat_1',
                'name': 'Alimentação',
                'kind': 'expense',
                'icon_key': 'restaurant',
              },
              {
                'id': 'cat_2',
                'name': 'Moradia',
                'kind': 'expense',
                'icon_key': 'house',
              },
            ],
            'tasks': [
              {'id': 'task_1', 'title': 'Pagar aluguel'},
            ],
          };
          final checksum = await BackupBundle.computeChecksum(tables);
          final bundle = BackupBundle(
            schemaVersion: db.schemaVersion,
            exportedAt: '2026-10-01T12:00:00Z',
            tables: tables,
            csv: {},
            checksum: checksum,
          );

          final jsonString = bundle.toJsonString();
          final previewRes = await backupService.previewBackup(jsonString);

          expect(previewRes.isOk, isTrue);
          final preview = previewRes.valueOrNull!;
          expect(preview.schemaVersion, equals(db.schemaVersion));
          expect(preview.totalRecords, equals(3));
          expect(preview.tableRecordCounts['categories'], equals(2));
          expect(preview.tableRecordCounts['tasks'], equals(1));

          // Banco original permanece vazio
          expect(await db.categories.count().getSingle(), equals(0));
        });

        test('importBackup with ImportMode.replace deletes existing data and replaces with backup', () async {
          // Populate local database with old category
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_antiga',
                  name: 'Antiga',
                  kind: 'expense',
                  iconKey: 'old',
                ),
              );
          expect(await db.categories.count().getSingle(), equals(1));

          final tables = {
            'categories': [
              {
                'id': 'cat_nova',
                'name': 'Nova Categoria',
                'kind': 'expense',
                'icon_key': 'new',
              },
            ],
          };
          final checksum = await BackupBundle.computeChecksum(tables);
          final bundle = BackupBundle(
            schemaVersion: db.schemaVersion,
            exportedAt: '2026-10-01T12:00:00Z',
            tables: tables,
            csv: {},
            checksum: checksum,
          );

          final importRes = await backupService.importBackup(
            bundle.toJsonString(),
            mode: ImportMode.replace,
          );
          expect(importRes.isOk, isTrue);

          // Banco agora tem apenas a nova categoria
          final cats = await db.select(db.categories).get();
          expect(cats.length, equals(1));
          expect(cats.first.id, equals('cat_nova'));
        });

        test('importBackup with ImportMode.merge preserves non-conflicting local records and adds/updates backup records', () async {
          // Popula banco local com cat_1 e cat_2
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_local_1',
                  name: 'Local A',
                  kind: 'expense',
                  iconKey: 'local',
                ),
              );
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_local_2',
                  name: 'Local B',
                  kind: 'expense',
                  iconKey: 'local',
                ),
              );

          // Backup contains cat_local_1 (with updated name) and cat_backup_3
          final tables = {
            'categories': [
              {
                'id': 'cat_local_1',
                'name': 'Local A Atualizado',
                'kind': 'expense',
                'icon_key': 'local',
              },
              {
                'id': 'cat_backup_3',
                'name': 'Backup C',
                'kind': 'expense',
                'icon_key': 'backup',
              },
            ],
          };
          final checksum = await BackupBundle.computeChecksum(tables);
          final bundle = BackupBundle(
            schemaVersion: db.schemaVersion,
            exportedAt: '2026-10-01T12:00:00Z',
            tables: tables,
            csv: {},
            checksum: checksum,
          );

          final importRes = await backupService.importBackup(
            bundle.toJsonString(),
            mode: ImportMode.merge,
          );
          expect(importRes.isOk, isTrue);

          // Database now contains cat_local_1 (updated), cat_local_2 (preserved) and cat_backup_3 (added)
          final cats = await db.select(db.categories).get();
          expect(cats.length, equals(3));

          final catMap = {for (final c in cats) c.id: c.name};
          expect(catMap['cat_local_1'], equals('Local A Atualizado'));
          expect(catMap['cat_local_2'], equals('Local B'));
          expect(catMap['cat_backup_3'], equals('Backup C'));
        });
      },
    );

    group('T-04 — RF-007, RN-234, CA-3.1 Criptografia do Backup', () {
      test('exportEncryptedBackup gera arquivo criptografado no formato AES-256-GCM + Argon2id', () async {
        await populateFullDatabase(db);

        final exportRes = await backupService.exportEncryptedBackup(
          'senha_segura_123',
        );
        expect(exportRes.isOk, isTrue);

        final encryptedData = exportRes.valueOrNull!;
        expect(encryptedData, contains('my_sweet_home_encrypted_backup'));
        expect(encryptedData, contains('AES-256-GCM'));
        expect(encryptedData, contains('Argon2id'));
        expect(encryptedData, isNot(contains('Almoço de negócios')));
        expect(encryptedData, isNot(contains('Leite Integral')));
      });

      test(
        'importEncryptedBackup with correct password restores data cleanly',
        () async {
          await populateFullDatabase(db);

          final exportRes = await backupService.exportEncryptedBackup(
            'senha_segura_123',
          );
          expect(exportRes.isOk, isTrue);
          final encryptedData = exportRes.valueOrNull!;

          final cleanDb = AppDatabase.memory();
          final cleanService = DriftBackupService(cleanDb);

          try {
            final importRes = await cleanService.importEncryptedBackup(
              encryptedData,
              'senha_segura_123',
            );
            expect(importRes.isOk, isTrue);

            expect(
              await cleanDb.categories.count().getSingle(),
              equals(await db.categories.count().getSingle()),
            );
            expect(
              await cleanDb.expenses.count().getSingle(),
              equals(await db.expenses.count().getSingle()),
            );
            expect(
              await cleanDb.purchases.count().getSingle(),
              equals(await db.purchases.count().getSingle()),
            );
          } finally {
            await cleanDb.close();
          }
        },
      );

      test('CA-3.1 — Restoring encrypted backup with wrong password fails with message and NOTHING is applied', () async {
        await populateFullDatabase(db);

        final exportRes = await backupService.exportEncryptedBackup(
          'senha_correta_123',
        );
        expect(exportRes.isOk, isTrue);
        final encryptedData = exportRes.valueOrNull!;

        // Pre-existing target database with 1 category
        final targetDb = AppDatabase.memory();
        final targetService = DriftBackupService(targetDb);

        try {
          await targetDb
              .into(targetDb.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_existente',
                  name: 'Existente',
                  kind: 'expense',
                  iconKey: 'exist',
                ),
              );
          expect(await targetDb.categories.count().getSingle(), equals(1));

          // Tenta restaurar com senha errada
          final importRes = await targetService.importEncryptedBackup(
            encryptedData,
            'senha_errada_999',
          );

          expect(importRes.isErr, isTrue);
          final failure = importRes.failureOrNull!;
          expect(failure, isA<ValidationFailure>());
          expect(
            (failure as ValidationFailure).fields['password'],
            contains('Senha incorreta ou arquivo de backup corrompido'),
          );

          // Validate that nothing was modified or applied in database
          final catsAfter = await targetDb.select(targetDb.categories).get();
          expect(catsAfter.length, equals(1));
          expect(catsAfter.first.id, equals('cat_existente'));
          expect(await targetDb.expenses.count().getSingle(), equals(0));
        } finally {
          await targetDb.close();
        }
      });
    });

    group('T-06 — Restore with integrity validation, all-or-nothing (RN-236, CA-3.2)', () {
      test('CA-3.2 — Restoring backup with corrupted checksum/hash is prevented and NOTHING is applied to database', () async {
        final bundle = BackupBundle(
          schemaVersion: db.schemaVersion,
          exportedAt: '2026-10-01T12:00:00Z',
          tables: {
            'categories': [
              {
                'id': 'cat_valida',
                'name': 'Alimentação',
                'kind': 'expense',
                'icon_key': 'rest',
              },
            ],
          },
          csv: {},
          checksum: 'hash_sha256_forjado_e_invalido_12345',
        );

        final targetDb = AppDatabase.memory();
        final targetService = DriftBackupService(targetDb);

        try {
          // Insert 1 record into destination database to validate it is not destroyed
          await targetDb
              .into(targetDb.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_original',
                  name: 'Original',
                  kind: 'expense',
                  iconKey: 'orig',
                ),
              );
          expect(await targetDb.categories.count().getSingle(), equals(1));

          final importRes = await targetService.importBackup(
            bundle.toJsonString(),
          );
          expect(importRes.isErr, isTrue);

          final failure = importRes.failureOrNull!;
          expect(failure, isA<ValidationFailure>());
          expect(
            (failure as ValidationFailure).fields['backup'],
            contains('Falha na validação de integridade (hash) do backup'),
          );

          // Banco permaneceu 100% intocado (tudo ou nada)
          final cats = await targetDb.select(targetDb.categories).get();
          expect(cats.length, equals(1));
          expect(cats.first.id, equals('cat_original'));
        } finally {
          await targetDb.close();
        }
      });

      test('RN-236 — Altering data without updating checksum causes failure in preview and import', () async {
        final originalChecksum = await BackupBundle.computeChecksum({
          'categories': [
            {
              'id': 'cat_1',
              'name': 'Saúde',
              'kind': 'expense',
              'icon_key': 'health',
            },
          ],
        });

        // Modifies name without recalculating checksum
        final tamperedBundleMap = {
          'schema_version': db.schemaVersion,
          'exported_at': '2026-10-01T12:00:00Z',
          'checksum': originalChecksum,
          'tables': {
            'categories': [
              {
                'id': 'cat_1',
                'name': 'Saúde Alterado',
                'kind': 'expense',
                'icon_key': 'health',
              },
            ],
          },
          'csv': <String, String>{},
        };

        final jsonString = const JsonEncoder.withIndent('  ')
            .convert(tamperedBundleMap);

        // 1. previewBackup detects corruption/tampering
        final previewRes = await backupService.previewBackup(jsonString);
        expect(previewRes.isErr, isTrue);
        expect(
          (previewRes.failureOrNull as ValidationFailure).fields['backup'],
          contains('Falha na validação de integridade'),
        );

        // 2. importBackup detects corruption/tampering
        final importRes = await backupService.importBackup(jsonString);
        expect(importRes.isErr, isTrue);
        expect(
          (importRes.failureOrNull as ValidationFailure).fields['backup'],
          contains('Falha na validação de integridade'),
        );
      });

      test('RN-236 — Corrupted encrypted backup (altered payload/MAC) fails without applying partial changes', () async {
        await populateFullDatabase(db);
        final exportRes = await backupService.exportEncryptedBackup(
          'senha_valida_123',
        );
        expect(exportRes.isOk, isTrue);

        final encryptedJson = exportRes.valueOrNull!;
        final decodedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

        // Adultera os bytes do ciphertext
        decodedMap['ciphertext'] = base64Encode(
          utf8.encode('ciphertext_corrompido_1234567890'),
        );
        final tamperedEncryptedJson = jsonEncode(decodedMap);

        final targetDb = AppDatabase.memory();
        final targetService = DriftBackupService(targetDb);

        try {
          await targetDb
              .into(targetDb.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'cat_intacta',
                  name: 'Intacta',
                  kind: 'expense',
                  iconKey: 'ok',
                ),
              );

          final importRes = await targetService.importEncryptedBackup(
            tamperedEncryptedJson,
            'senha_valida_123',
          );

          expect(importRes.isErr, isTrue);
          expect(importRes.failureOrNull, isA<ValidationFailure>());

          // Nada foi alterado no banco de destino
          final cats = await targetDb.select(targetDb.categories).get();
          expect(cats.length, equals(1));
          expect(cats.first.id, equals('cat_intacta'));
        } finally {
          await targetDb.close();
        }
      });

      test(
        'Tudo ou nada — Erro durante inserção na transação faz rollback total',
        () async {
          final targetDb = AppDatabase.memory();
          final targetService = DriftBackupService(targetDb);

          try {
            // Insere categoria inicial
            await targetDb
                .into(targetDb.categories)
                .insert(
                  CategoriesCompanion.insert(
                    id: 'cat_base',
                    name: 'Base',
                    kind: 'expense',
                    iconKey: 'base',
                  ),
                );
            expect(await targetDb.categories.count().getSingle(), equals(1));

            final badTables = {
              'categories': [
                {
                  'id': 'cat_nova_1',
                  'name': 'Nova 1',
                  'kind': 'expense',
                  'icon_key': 'n1',
                },
              ],
              'expenses': [
                // Coluna inexistente no schema faz o SQL estourar durante o INSERT da tabela expenses
                {'id': 'exp_invalid', 'coluna_inexistente_que_causa_erro': 123},
              ],
            };
            final checksum = await BackupBundle.computeChecksum(badTables);

            // Bundle with 1 valid row and 1 invalid row (failing in SQL)
            final badTableBundle = BackupBundle(
              schemaVersion: targetDb.schemaVersion,
              exportedAt: '2026-10-01T12:00:00Z',
              tables: badTables,
              csv: {},
              checksum: checksum,
            );

            final importRes = await targetService.importBackup(
              badTableBundle.toJsonString(),
              mode: ImportMode.replace,
            );

            expect(importRes.isErr, isTrue);
            expect(importRes.failureOrNull, isA<StorageFailure>());

            // Due to full transaction rollback ("all-or-nothing"), cat_base was preserved!
            // And cat_nova_1 was NOT partially saved in database.
            final catsAfter = await targetDb.select(targetDb.categories).get();
            expect(catsAfter.length, equals(1));
            expect(catsAfter.first.id, equals('cat_base'));
          } finally {
            await targetDb.close();
          }
        },
      );

      test('RN-236 — Rejeita backup sem checksum (ausente, nulo ou vazio) impedindo bypass de integridade', () async {
        final bundleMapNoChecksum = {
          'schema_version': db.schemaVersion,
          'exported_at': '2026-10-01T12:00:00Z',
          'tables': {
            'categories': [
              {
                'id': 'cat_tampered',
                'name': 'Adulterado Sem Hash',
                'kind': 'expense',
                'icon_key': 'hack',
              },
            ],
          },
          'csv': <String, String>{},
        };

        final jsonString = jsonEncode(bundleMapNoChecksum);

        final importRes = await backupService.importBackup(jsonString);
        expect(importRes.isErr, isTrue);
        expect(
          (importRes.failureOrNull as ValidationFailure).fields['backup'],
          contains('Falha na validação de integridade'),
        );
      });

      test('RN-236 — computeChecksum is deterministic regardless of key insertion order in maps', () async {
        final tablesA = {
          'categories': [
            {
              'name': 'Alimentação',
              'id': 'cat_1',
              'kind': 'expense',
              'icon_key': 'food',
            },
          ],
          'tasks': [
            {'title': 'Comprar pão', 'id': 'task_1'},
          ],
        };

        final tablesB = {
          'tasks': [
            {'id': 'task_1', 'title': 'Comprar pão'},
          ],
          'categories': [
            {
              'id': 'cat_1',
              'kind': 'expense',
              'name': 'Alimentação',
              'icon_key': 'food',
            },
          ],
        };

        final hashA = await BackupBundle.computeChecksum(tablesA);
        final hashB = await BackupBundle.computeChecksum(tablesB);

        expect(hashA, equals(hashB));
      });
    });

    group(
      'T-07 — Fotos fora do backup por padrão, com tamanho estimado (RN-237)',
      () {
        test('estimatePhotosSize retorna o tamanho em bytes de fotos referenciadas nas compras e receitas', () async {
          final photoBytes1 = Uint8List.fromList([1, 2, 3, 4, 5]); // 5 bytes
          final photoBytes2 = Uint8List.fromList([
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
            90,
            100,
          ]); // 10 bytes

          await fakeFileStore.save(photoBytes1, name: 'receipt_1.jpg');
          await fakeFileStore.save(photoBytes2, name: 'recipe_1.jpg');

          await db
              .into(db.purchases)
              .insert(
                PurchasesCompanion.insert(
                  id: 'p_photo',
                  purchasedAt: '2026-09-20',
                  totalCents: 1000,
                  receiptImagePath: const Value('/app/storage/receipt_1.jpg'),
                  source: 'manual',
                ),
              );

          await db
              .into(db.recipes)
              .insert(
                RecipesCompanion.insert(
                  id: 'r_photo',
                  title: 'Receita Foto',
                  photoPath: const Value('/app/storage/recipe_1.jpg'),
                ),
              );

          final sizeRes = await backupService.estimatePhotosSize();
          expect(sizeRes.isOk, isTrue);
          expect(sizeRes.valueOrNull, equals(15));
        });

        test('exportBackup omits photos by default (includePhotos = false) per RN-237', () async {
          final photoBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
          await fakeFileStore.save(photoBytes, name: 'receipt_1.jpg');

          await db
              .into(db.purchases)
              .insert(
                PurchasesCompanion.insert(
                  id: 'p_photo',
                  purchasedAt: '2026-09-20',
                  totalCents: 1000,
                  receiptImagePath: const Value('/app/storage/receipt_1.jpg'),
                  source: 'manual',
                ),
              );

          final exportRes = await backupService.exportBackup();
          expect(exportRes.isOk, isTrue);
          final bundle = exportRes.valueOrNull!;

          expect(bundle.photos, isEmpty);
        });

        test(
          'exportBackup inclui fotos em Base64 quando includePhotos = true',
          () async {
            final photoBytes = Uint8List.fromList([65, 66, 67]); // "ABC"
            await fakeFileStore.save(photoBytes, name: 'receipt_1.jpg');

            await db
                .into(db.purchases)
                .insert(
                  PurchasesCompanion.insert(
                    id: 'p_photo',
                    purchasedAt: '2026-09-20',
                    totalCents: 1000,
                    receiptImagePath: const Value('/app/storage/receipt_1.jpg'),
                    source: 'manual',
                  ),
                );

            final exportRes = await backupService.exportBackup(
              includePhotos: true,
            );
            expect(exportRes.isOk, isTrue);
            final bundle = exportRes.valueOrNull!;

            expect(bundle.photos, hasLength(1));
            expect(
              bundle.photos['/app/storage/receipt_1.jpg'],
              equals(base64Encode(photoBytes)),
            );
          },
        );

        test('importBackup com fotos restaura os arquivos de imagem no FileStorePort', () async {
          final photoBytes = Uint8List.fromList([10, 20, 30]);
          final encodedPhoto = base64Encode(photoBytes);

          final tables = {
            'purchases': [
              {
                'id': 'p_photo',
                'purchased_at': '2026-09-20',
                'total_cents': 1000,
                'receipt_image_path': '/app/storage/receipt_1.jpg',
                'source': 'manual',
              },
            ],
          };
          final checksum = await BackupBundle.computeChecksum(tables);

          final bundle = BackupBundle(
            schemaVersion: db.schemaVersion,
            exportedAt: '2026-10-01T12:00:00Z',
            tables: tables,
            csv: {},
            photos: {'/app/storage/receipt_1.jpg': encodedPhoto},
            checksum: checksum,
          );

          final cleanDb = AppDatabase.memory();
          final cleanFileStore = FakeFileStore();
          final cleanService = DriftBackupService(
            cleanDb,
            fileStore: cleanFileStore,
          );

          try {
            final importRes = await cleanService.importBackup(
              bundle.toJsonString(),
            );
            expect(importRes.isOk, isTrue);

            final restoredBytes = await cleanFileStore.read(
              '/app/storage/receipt_1.jpg',
            );
            expect(restoredBytes, equals(photoBytes));
          } finally {
            await cleanDb.close();
          }
        });
      },
    );
  });
}
