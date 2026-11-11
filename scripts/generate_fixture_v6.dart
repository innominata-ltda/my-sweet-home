// ignore_for_file: depend_on_referenced_packages, avoid_print, prefer_single_quotes, deprecated_member_use

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main() {
  final v5File = File('test/fixtures/db/v5.sqlite');
  final v6File = File('test/fixtures/db/v6_populated.sqlite');

  if (!v5File.existsSync()) {
    print('Error: test/fixtures/db/v5.sqlite not found.');
    exit(1);
  }

  if (v6File.existsSync()) {
    v6File.deleteSync();
  }
  v5File.copySync(v6File.path);

  final db = sqlite3.open(v6File.path);

  const now = '2026-10-29T12:00:00.000Z';

  // Ensure expense columns conform to data model
  final expCols = db
      .select("PRAGMA table_info(expenses);")
      .map((r) => r['name'] as String)
      .toSet();
  if (!expCols.contains('notes')) {
    db.execute("ALTER TABLE expenses ADD COLUMN notes TEXT;");
  }

  // Create sync tables introduced in v6
  db.execute('''
    CREATE TABLE sync_household (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      local_site_id TEXT NOT NULL,
      shared_areas TEXT NOT NULL,
      created_at TEXT NOT NULL,
      joined_at TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE sync_members (
      id TEXT PRIMARY KEY,
      household_id TEXT NOT NULL REFERENCES sync_household(id) ON DELETE CASCADE,
      site_id TEXT NOT NULL,
      name TEXT NOT NULL,
      joined_at TEXT NOT NULL,
      last_seen_at TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      UNIQUE(household_id, site_id)
    );

    CREATE TABLE sync_column_versions (
      table_name TEXT NOT NULL,
      row_id TEXT NOT NULL,
      column_name TEXT NOT NULL,
      hlc TEXT NOT NULL,
      site_id TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY(table_name, row_id, column_name)
    );
    CREATE INDEX idx_sync_col_ver_table_row ON sync_column_versions(table_name, row_id);
    CREATE INDEX idx_sync_col_ver_site_hlc ON sync_column_versions(site_id, hlc);

    CREATE TABLE sync_row_tombstones (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      row_id TEXT NOT NULL,
      hlc TEXT NOT NULL,
      purged_at TEXT NOT NULL,
      UNIQUE(table_name, row_id)
    );

    CREATE TABLE sync_peer_vectors (
      household_id TEXT NOT NULL,
      site_id TEXT NOT NULL,
      hlc TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY(household_id, site_id)
    );
  ''');

  // Populate v6 sync data with real members and pseudo-members
  db.execute('''
    INSERT INTO sync_household VALUES ('house-1', 'Casa Teste', 'site_local', 'catalog,home,finance', '$now', '$now', 1);

    INSERT INTO sync_members VALUES ('m-1', 'house-1', 'site_abc', 'Aparelho Real', '$now', '$now', 1);
    INSERT INTO sync_members VALUES ('m-2', 'house-1', 'probed_192.168.1.15', 'Pseudo Probe', '$now', '$now', 1);
    INSERT INTO sync_members VALUES ('m-3', 'house-1', 'cached_peer', 'Cached Peer', '$now', '$now', 1);

    INSERT INTO sync_peer_vectors VALUES ('house-1', 'site_abc', '1700000000000:0001:site_abc', '$now');
  ''');

  // Set schema version to 6
  db.execute('PRAGMA user_version = 6;');

  db.close();
  print('v6_populated.sqlite generated successfully at ${v6File.path}');
}
