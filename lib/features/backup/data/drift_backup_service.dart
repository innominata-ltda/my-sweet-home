import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/concurrency/background_runner_port.dart';
import 'package:my_sweet_home/core/concurrency/isolate_background_runner_adapter.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/storage/file_store_port.dart';
import 'package:my_sweet_home/core/storage/io_file_store_adapter.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/backup/data/backup_encryption_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_bundle.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

/// Backup service implementation using Drift ([AppDatabase]).
class DriftBackupService implements BackupService {
  final AppDatabase db;
  final Clock clock;
  final BackupEncryptionService encryptionService;
  final FileStorePort fileStore;
  final SecurityLimits limits;
  final BackgroundRunnerPort runner;

  DriftBackupService(
    this.db, {
    this.clock = const SystemClock(),
    BackupEncryptionService? encryptionService,
    FileStorePort? fileStore,
    SecurityLimits? limits,
    BackgroundRunnerPort? runner,
  }) : limits = limits ?? const SecurityLimits(),
       runner = runner ?? const IsolateBackgroundRunnerAdapter(),
       encryptionService =
           encryptionService ??
           BackupEncryptionService(limits: limits ?? const SecurityLimits()),
       fileStore = fileStore ?? const IoFileStoreAdapter();

  /// Tables ordered for insertion (parents before children to respect FKs).
  static const List<String> _tableInsertionOrder = [
    'categories',
    'products',
    'product_aliases',
    'product_denials',
    'stores',
    'recurring_rules',
    'budgets',
    'purchases',
    'expenses',
    'purchase_items',
    'price_points',
    'bills',
    'bill_payments',
    'shopping_lists',
    'shopping_items',
    'tasks',
    'recipes',
    'recipe_ingredients',
    'recipe_tags',
    'stock_items',
    'checklist_items',
    'settings',
    'consents',
    'attachments',
  ];

  /// Tables ordered for deletion (children before parents).
  static List<String> get _tableDeletionOrder =>
      _tableInsertionOrder.reversed.toList();

  Future<Set<String>> _getReferencedPhotoPaths() async {
    final paths = <String>{};

    try {
      final purchasesList = await (db.select(
        db.purchases,
      )..where((tbl) => tbl.receiptImagePath.isNotNull())).get();
      for (final p in purchasesList) {
        final path = p.receiptImagePath;
        if (path != null && path.isNotEmpty) paths.add(path);
      }
    } catch (_) {}

    try {
      final recipesList = await (db.select(
        db.recipes,
      )..where((tbl) => tbl.photoPath.isNotNull())).get();
      for (final r in recipesList) {
        final path = r.photoPath;
        if (path != null && path.isNotEmpty) paths.add(path);
      }
    } catch (_) {}

    try {
      final attachmentsList = await db.select(db.attachments).get();
      for (final a in attachmentsList) {
        if (a.path.isNotEmpty) paths.add(a.path);
      }
    } catch (_) {}

    return paths;
  }

  @override
  Future<Result<int, Failure>> estimatePhotosSize() async {
    try {
      final photoPaths = await _getReferencedPhotoPaths();
      int totalSize = 0;
      for (final path in photoPaths) {
        final size = await fileStore.getSize(path);
        totalSize += size;
      }
      return Ok(totalSize);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao estimar tamanho das fotos: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<BackupBundle, Failure>> exportBackup({
    bool includePhotos = false,
  }) async {
    try {
      final tablesMap = <String, List<Map<String, dynamic>>>{};

      for (final tableName in _tableInsertionOrder) {
        final rows = await db.customSelect('SELECT * FROM $tableName;').get();
        final rawList = rows
            .map((r) => Map<String, dynamic>.from(r.data))
            .toList();

        final sanitizedList = rawList.where((row) {
          if (tableName == 'settings' || tableName == 'consents') {
            final key = row['key']?.toString() ?? '';
            final val = row['value']?.toString();
            if (isSensitiveSettingKey(key) || isSensitiveSettingValue(val)) {
              return false;
            }
          }
          return true;
        }).toList();

        tablesMap[tableName] = sanitizedList;
      }

      final photosMap = <String, String>{};
      if (includePhotos) {
        final photoPaths = await _getReferencedPhotoPaths();
        for (final path in photoPaths) {
          final bytes = await fileStore.read(path);
          if (bytes != null && bytes.isNotEmpty) {
            photosMap[path] = base64Encode(bytes);
          }
        }
      }

      final expensesCsvRes = await exportExpensesCsv();
      final expensesCsv = expensesCsvRes.valueOrNull ?? '';

      final purchasesCsvRes = await exportPurchasesCsv();
      final purchasesCsv = purchasesCsvRes.valueOrNull ?? '';

      final checksum = await BackupBundle.computeChecksum(tablesMap);

      final bundle = BackupBundle(
        schemaVersion: db.schemaVersion,
        exportedAt: clock.nowUtc().toIso8601String(),
        tables: tablesMap,
        csv: {'expenses': expensesCsv, 'purchases': purchasesCsv},
        photos: photosMap,
        checksum: checksum,
      );

      return Ok(bundle);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao exportar backup: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<BackupPreview, Failure>> previewBackup(
    String jsonContent,
  ) async {
    if (jsonContent.length > limits.maxBackupBytes) {
      return const Err(
        ValidationFailure(
          fields: {'backup': 'Arquivo excede o tamanho máximo suportado.'},
        ),
      );
    }
    try {
      BackupBundle bundle;
      try {
        bundle = BackupBundle.fromJsonString(jsonContent);
      } catch (e) {
        return Err(
          ValidationFailure(
            fields: {
              'backup':
                  'Formato de arquivo de backup inválido ou corrompido: $e',
            },
          ),
        );
      }

      final isIntegrityValid = await bundle.verifyIntegrity();
      if (!isIntegrityValid) {
        return const Err(
          ValidationFailure(
            fields: {
              'backup': 'Falha na validação de integridade (hash) do backup. O arquivo pode estar corrompido ou ter sido alterado.',
            },
          ),
        );
      }

      if (bundle.schemaVersion < 1) {
        return const Err(
          ValidationFailure(
            fields: {'schemaVersion': 'Versão de schema de backup inválida.'},
          ),
        );
      }

      if (bundle.schemaVersion > db.schemaVersion) {
        return Err(
          StorageFailure(
            detail:
                'A versão do schema do backup (v${bundle.schemaVersion}) é mais recente '
                'que a versão suportada pelo aplicativo (v${db.schemaVersion}). '
                'Atualize o aplicativo para restaurar este backup.',
          ),
        );
      }

      final tableRecordCounts = <String, int>{};
      int totalRecords = 0;

      for (final entry in bundle.tables.entries) {
        final count = entry.value.length;
        if (count > 0) {
          tableRecordCounts[entry.key] = count;
          totalRecords += count;
        }
      }

      final preview = BackupPreview(
        schemaVersion: bundle.schemaVersion,
        exportedAt: bundle.exportedAt,
        totalRecords: totalRecords,
        tableRecordCounts: tableRecordCounts,
      );

      return Ok(preview);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao gerar pré-visualização do backup: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> importBackup(
    String jsonContent, {
    ImportMode mode = ImportMode.replace,
  }) async {
    if (jsonContent.length > limits.maxBackupBytes) {
      return const Err(
        ValidationFailure(
          fields: {'backup': 'Arquivo excede o tamanho máximo suportado.'},
        ),
      );
    }
    try {
      BackupBundle bundle;
      try {
        bundle = BackupBundle.fromJsonString(jsonContent);
      } catch (e) {
        return Err(
          ValidationFailure(
            fields: {
              'backup':
                  'Formato de arquivo de backup inválido ou corrompido: $e',
            },
          ),
        );
      }

      final isIntegrityValid = await bundle.verifyIntegrity();
      if (!isIntegrityValid) {
        return const Err(
          ValidationFailure(
            fields: {
              'backup': 'Falha na validação de integridade (hash) do backup. O arquivo pode estar corrompido ou ter sido alterado.',
            },
          ),
        );
      }

      if (bundle.schemaVersion < 1) {
        return const Err(
          ValidationFailure(
            fields: {'schemaVersion': 'Versão de schema de backup inválida.'},
          ),
        );
      }

      if (bundle.schemaVersion > db.schemaVersion) {
        return Err(
          StorageFailure(
            detail:
                'A versão do schema do backup (v${bundle.schemaVersion}) é mais recente '
                'que a versão suportada pelo aplicativo (v${db.schemaVersion}). '
                'Atualize o aplicativo para restaurar este backup.',
          ),
        );
      }

      await db.customStatement('PRAGMA foreign_keys = OFF;');
      try {
        await db.transaction(() async {
          if (mode == ImportMode.replace) {
            for (final tableName in _tableDeletionOrder) {
              await db.customStatement('DELETE FROM $tableName;');
            }
          }

          for (final tableName in _tableInsertionOrder) {
            final rows = bundle.tables[tableName];
            if (rows == null || rows.isEmpty) continue;

            for (final row in rows) {
              if (row.isEmpty) continue;

              final columns = row.keys.toList();
              final placeholders = List.filled(columns.length, '?').join(', ');
              final sql = mode == ImportMode.replace
                  ? 'INSERT INTO $tableName (${columns.join(', ')}) VALUES ($placeholders);'
                  : 'INSERT OR REPLACE INTO $tableName (${columns.join(', ')}) VALUES ($placeholders);';

              final variables = row.values.map(_toVariable).toList();
              await db.customInsert(sql, variables: variables);
            }
          }

          if (bundle.photos.isNotEmpty) {
            for (final entry in bundle.photos.entries) {
              if (entry.value.isNotEmpty) {
                try {
                  final bytes = base64Decode(entry.value);
                  await fileStore.save(bytes, name: entry.key);
                } catch (_) {}
              }
            }
          }
        });
      } finally {
        await db.customStatement('PRAGMA foreign_keys = ON;');
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao importar backup: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<String, Failure>> exportExpensesCsv() async {
    try {
      final categoriesRows = await db
          .customSelect('SELECT id, name FROM categories;')
          .get();
      final categoryMap = {
        for (final row in categoriesRows)
          row.read<String>('id'): row.read<String>('name'),
      };

      final expensesRows = await db
          .customSelect(
            'SELECT * FROM expenses WHERE deleted_at IS NULL ORDER BY occurred_on DESC;',
          )
          .get();

      final buffer = StringBuffer();
      buffer.write('\uFEFF'); // UTF-8 BOM
      buffer.writeln('Data;Descrição;Categoria;Valor');

      for (final row in expensesRows) {
        final dataMap = row.data;
        final dateStr = BackupCsvFormatter.formatDate(
          dataMap['occurred_on']?.toString(),
        );
        final desc = BackupCsvFormatter.escapeCsvField(
          dataMap['description']?.toString(),
        );
        final catId = dataMap['category_id']?.toString();
        final rawCatName = catId != null
            ? (categoryMap[catId] ?? 'Sem Categoria')
            : 'Sem Categoria';
        final catName = BackupCsvFormatter.escapeCsvField(rawCatName);
        final amountCents = dataMap['amount_cents'] as int? ?? 0;
        final valStr = BackupCsvFormatter.formatCents(amountCents);

        buffer.writeln('$dateStr;$desc;$catName;$valStr');
      }

      return Ok(buffer.toString());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao gerar CSV de despesas: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<String, Failure>> exportPurchasesCsv() async {
    try {
      final storesRows = await db
          .customSelect('SELECT id, name, cnpj FROM stores;')
          .get();
      final storeMap = <String, Map<String, String>>{};
      for (final row in storesRows) {
        final id = row.read<String>('id');
        final name = row.read<String>('name');
        final cnpj = row.read<String?>('cnpj') ?? '';
        storeMap[id] = {'name': name, 'cnpj': cnpj};
      }

      final purchasesRows = await db
          .customSelect(
            'SELECT * FROM purchases WHERE deleted_at IS NULL ORDER BY purchased_at DESC;',
          )
          .get();

      final buffer = StringBuffer();
      buffer.write('\uFEFF'); // UTF-8 BOM
      buffer.writeln(
        'Data;Estabelecimento;CNPJ;Total;Desconto;Forma de Pagamento',
      );

      for (final row in purchasesRows) {
        final dataMap = row.data;
        final dateStr = BackupCsvFormatter.formatDate(
          dataMap['purchased_at']?.toString(),
        );
        final storeId = dataMap['store_id']?.toString();
        final storeInfo = storeId != null ? storeMap[storeId] : null;
        final storeName = BackupCsvFormatter.escapeCsvField(
          storeInfo?['name'] ?? '',
        );
        final storeCnpj = BackupCsvFormatter.escapeCsvField(
          storeInfo?['cnpj'] ?? '',
        );
        final totalCents = dataMap['total_cents'] as int? ?? 0;
        final discountCents = dataMap['discount_cents'] as int? ?? 0;
        final totalStr = BackupCsvFormatter.formatCents(totalCents);
        final discountStr = BackupCsvFormatter.formatCents(discountCents);
        final payment = BackupCsvFormatter.escapeCsvField(
          dataMap['payment_method']?.toString() ?? '',
        );

        buffer.writeln(
          '$dateStr;$storeName;$storeCnpj;$totalStr;$discountStr;$payment',
        );
      }

      return Ok(buffer.toString());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao gerar CSV de compras: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<String, Failure>> exportEncryptedBackup(
    String password, {
    bool includePhotos = false,
    void Function(BackupStage stage)? onStage,
  }) async {
    onStage?.call(BackupStage.collecting);
    final exportRes = await exportBackup(includePhotos: includePhotos);
    if (exportRes.isErr) return Err(exportRes.failureOrNull!);

    onStage?.call(BackupStage.encrypting);
    final bundle = exportRes.valueOrNull!;
    final encService = encryptionService;

    final encryptionRes = await runner.run(() {
      final jsonString = bundle.toJsonString();
      return encService.encrypt(plainText: jsonString, password: password);
    });

    if (encryptionRes.isErr) return encryptionRes;

    onStage?.call(BackupStage.writing);
    onStage?.call(BackupStage.done);

    return encryptionRes;
  }

  @override
  Future<Result<void, Failure>> importEncryptedBackup(
    String encryptedContent,
    String password, {
    ImportMode mode = ImportMode.replace,
  }) async {
    if (encryptedContent.length > limits.maxBackupBytes) {
      return const Err(
        ValidationFailure(
          fields: {'backup': 'Arquivo excede o tamanho máximo suportado.'},
        ),
      );
    }

    final encService = encryptionService;
    final decryptRes = await runner.run(() {
      return encService.decrypt(
        encryptedContent: encryptedContent,
        password: password,
      );
    });

    if (decryptRes.isErr) {
      return Err(decryptRes.failureOrNull!);
    }

    final jsonContent = decryptRes.valueOrNull!;
    return importBackup(jsonContent, mode: mode);
  }

  /// Returns `true` if configuration/consent key contains sensitive terms (RN-238).
  ///
  /// Utiliza limites de palavras (tokens) para evitar falsos positivos como `compass_mode`
  /// or `keyboard_vibration`, ensuring removal of tokens, passwords, keys and credentials.
  static bool isSensitiveSettingKey(String rawKey) {
    if (rawKey.trim().isEmpty) return false;

    final normalizedKey = rawKey
        .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (m) => '_')
        .toLowerCase();

    final tokens = normalizedKey
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    const sensitiveWords = {
      'token',
      'tokens',
      'password',
      'passwords',
      'passwd',
      'pwd',
      'pass',
      'passcode',
      'secret',
      'secrets',
      'auth',
      'cred',
      'creds',
      'credential',
      'credentials',
      'pin',
      'pins',
      'pincode',
      'hash',
      'hashes',
      'key',
      'keys',
      'session',
      'sessions',
      'bearer',
      'jwt',
      'private',
      'apikey',
      'apikeys',
    };

    for (final token in tokens) {
      if (sensitiveWords.contains(token)) {
        return true;
      }
    }

    if (normalizedKey.contains('password') ||
        normalizedKey.contains('passwd') ||
        normalizedKey.contains('secret') ||
        normalizedKey.contains('bearer') ||
        normalizedKey.contains('apikey') ||
        normalizedKey.contains('auth_token') ||
        normalizedKey.contains('access_token') ||
        normalizedKey.contains('refresh_token')) {
      return true;
    }

    return false;
  }

  /// Returns `true` if configuration value matches obvious credential/token patterns.
  static bool isSensitiveSettingValue(String? value) {
    if (value == null || value.isEmpty) return false;
    final valTrimmed = value.trim();
    final valLower = valTrimmed.toLowerCase();

    if (valLower.startsWith('bearer ')) return true;
    if (valTrimmed.startsWith('ey J') ||
        (valTrimmed.startsWith('eyJ') && valTrimmed.length > 20)) {
      return true;
    }
    return false;
  }

  Variable _toVariable(dynamic val) {
    if (val == null) return const Variable(null);
    if (val is int) return Variable.withInt(val);
    if (val is double) return Variable.withReal(val);
    if (val is bool) return Variable.withBool(val);
    if (val is String) return Variable.withString(val);
    return Variable.withString(val.toString());
  }
}
