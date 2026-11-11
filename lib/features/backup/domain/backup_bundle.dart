import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:intl/intl.dart';

/// Representation of data exported from the application with integrity validation (RN-236).
class BackupBundle {
  /// Database schema version at the time of export.
  final int schemaVersion;

  /// ISO 8601 timestamp of the export.
  final String exportedAt;

  /// Mapa tabela -> lista de registros (linhas em formato chave-valor).
  final Map<String, List<Map<String, dynamic>>> tables;

  /// Exported CSV contents (e.g. 'expenses', 'purchases').
  final Map<String, String> csv;

  /// Fotos e arquivos anexos exportados em Base64 (caminho -> base64) (RN-237).
  final Map<String, String> photos;

  /// SHA-256 integrity hash for table data.
  final String? checksum;

  const BackupBundle({
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
    required this.csv,
    this.photos = const {},
    this.checksum,
  });

  /// Computes SHA-256 checksum for table data.
  /// Table keys and record fields are sorted alphabetically
  /// to guarantee deterministic hash consistency.
  static Future<String> computeChecksum(
    Map<String, List<Map<String, dynamic>>> tables,
  ) async {
    final sortedTables = <String, List<Map<String, dynamic>>>{};
    final sortedTableNames = tables.keys.toList()..sort();

    for (final tableName in sortedTableNames) {
      final rows = tables[tableName]!;
      final sortedRows = rows.map((row) {
        final sortedKeys = row.keys.toList()..sort();
        return <String, dynamic>{for (final key in sortedKeys) key: row[key]};
      }).toList();
      sortedTables[tableName] = sortedRows;
    }

    final jsonString = jsonEncode(sortedTables);
    final bytes = utf8.encode(jsonString);
    final hash = await Sha256().hash(bytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Validates if bundle integrity checksum matches current data.
  Future<bool> verifyIntegrity() async {
    if (checksum == null || checksum!.isEmpty) {
      return false;
    }
    final calculated = await computeChecksum(tables);
    return calculated == checksum;
  }

  /// Converts this bundle to a serializable JSON map.
  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'exported_at': exportedAt,
      if (checksum != null) 'checksum': checksum,
      'tables': tables,
      'csv': csv,
      'photos': photos,
    };
  }

  /// Converts this bundle into a formatted JSON string.
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Constructs a [BackupBundle] from a JSON map (RN-236).
  factory BackupBundle.fromJson(Map<String, dynamic> json) {
    final version =
        json['schema_version'] as int? ?? json['schemaVersion'] as int?;
    if (version == null) {
      throw const FormatException('Versão de schema não encontrada no backup');
    }

    final exportedAt =
        json['exported_at'] as String? ?? json['exportedAt'] as String? ?? '';

    final checksum = json['checksum'] as String? ?? json['hash'] as String?;

    final tables = <String, List<Map<String, dynamic>>>{};
    if (json['tables'] is Map) {
      final rawTables = json['tables'] as Map;
      for (final entry in rawTables.entries) {
        final key = entry.key.toString();
        if (entry.value is List) {
          final rows = (entry.value as List)
              .whereType<Map<dynamic, dynamic>>()
              .map(Map<String, dynamic>.from)
              .toList();
          tables[key] = rows;
        }
      }
    } else {
      throw const FormatException('Estrutura de tabelas inválida no backup');
    }

    final csv = <String, String>{};
    if (json['csv'] is Map) {
      final rawCsv = json['csv'] as Map;
      for (final entry in rawCsv.entries) {
        csv[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    final photos = <String, String>{};
    if (json['photos'] is Map) {
      final rawPhotos = json['photos'] as Map;
      for (final entry in rawPhotos.entries) {
        photos[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    return BackupBundle(
      schemaVersion: version,
      exportedAt: exportedAt,
      tables: tables,
      csv: csv,
      photos: photos,
      checksum: checksum,
    );
  }

  /// Constructs a [BackupBundle] from a JSON string.
  factory BackupBundle.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupBundle.fromJson(decoded);
  }
}

/// Helper for CSV formatting (UTF-8, ';', comma decimal separator).
class BackupCsvFormatter {
  /// Formats a numeric value in cents as a comma decimal string (e.g. 1250 cents -> "12,50").
  static String formatCents(int cents) {
    final absCents = cents.abs();
    final sign = cents < 0 ? '-' : '';
    final units = absCents ~/ 100;
    final decimals = (absCents % 100).toString().padLeft(2, '0');
    return '$sign$units,$decimals';
  }

  /// Escapes a field for CSV (adds quotes if it contains semicolons, quotes or line breaks).
  static String escapeCsvField(String? field) {
    if (field == null) return '';
    if (field.contains(';') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Formata data ISO (ex: 2026-09-15T...) ou data simples em dd/MM/yyyy.
  static String formatDate(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateIso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateIso;
    }
  }
}
