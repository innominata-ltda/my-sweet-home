library;

import 'hlc.dart';

/// Represents the version of an individual table column (per-column LWW-register).
final class ColumnVersion {
  /// Database table name (e.g. 'products', 'shopping_items').
  final String table;

  /// Row primary key (typically UUID).
  final String rowId;

  /// Changed column name (e.g. 'canonical_name', 'quantity_milli').
  final String column;

  /// Serialized column value (int cents, int millis, ISO text, num, null).
  final Object? value;

  /// Hybrid Logical Clock timestamp when this version was recorded.
  final Hlc hlc;

  const ColumnVersion({
    required this.table,
    required this.rowId,
    required this.column,
    required this.value,
    required this.hlc,
  });

  /// Canonical key uniquely identifying the column within a row.
  String get key => '$table:$rowId:$column';

  /// Serializes column version to map/JSON.
  Map<String, dynamic> toJson() => {
    'table': table,
    'row_id': rowId,
    'column': column,
    'value': value,
    'hlc': hlc.pack(),
  };

  /// Reconstructs a [ColumnVersion] from map/JSON.
  factory ColumnVersion.fromJson(Map<String, dynamic> json) {
    final table =
        (json['table'] ?? json['table_name'] ?? json['tableName']) as String;
    final rowId = (json['row_id'] ?? json['rowId']) as String;
    final column =
        (json['column'] ?? json['column_name'] ?? json['columnName']) as String;
    final value = json['value'];
    final rawHlc = json['hlc'];
    final hlc = rawHlc is Hlc ? rawHlc : Hlc.parse(rawHlc as String);

    return ColumnVersion(
      table: table,
      rowId: rowId,
      column: column,
      value: value,
      hlc: hlc,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnVersion &&
          other.table == table &&
          other.rowId == rowId &&
          other.column == column &&
          other.value == value &&
          other.hlc == hlc;

  @override
  int get hashCode => Object.hash(table, rowId, column, value, hlc);

  @override
  String toString() => 'ColumnVersion($key = $value @ ${hlc.pack()})';
}
