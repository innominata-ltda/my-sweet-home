import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

void main() {
  group('T-15 — Fachada AppIcons', () {
    // ── Navigation ─────────────────────────────────────────────────────────────

    test('AppIcons.home existe', () => expect(AppIcons.home, isA<IconData>()));
    test(
      'AppIcons.homeActive existe',
      () => expect(AppIcons.homeActive, isA<IconData>()),
    );
    test(
      'AppIcons.shopping existe',
      () => expect(AppIcons.shopping, isA<IconData>()),
    );
    test(
      'AppIcons.shoppingActive existe',
      () => expect(AppIcons.shoppingActive, isA<IconData>()),
    );
    test(
      'AppIcons.tasks existe',
      () => expect(AppIcons.tasks, isA<IconData>()),
    );
    test(
      'AppIcons.tasksActive existe',
      () => expect(AppIcons.tasksActive, isA<IconData>()),
    );
    test(
      'AppIcons.recipes existe',
      () => expect(AppIcons.recipes, isA<IconData>()),
    );
    test(
      'AppIcons.recipesActive existe',
      () => expect(AppIcons.recipesActive, isA<IconData>()),
    );
    test(
      'AppIcons.settings existe',
      () => expect(AppIcons.settings, isA<IconData>()),
    );
    test(
      'AppIcons.settingsActive existe',
      () => expect(AppIcons.settingsActive, isA<IconData>()),
    );

    // ── Actions ─────────────────────────────────────────────────────────────────

    test('AppIcons.add existe', () => expect(AppIcons.add, isA<IconData>()));
    test('AppIcons.edit existe', () => expect(AppIcons.edit, isA<IconData>()));
    test(
      'AppIcons.delete existe',
      () => expect(AppIcons.delete, isA<IconData>()),
    );
    test('AppIcons.undo existe', () => expect(AppIcons.undo, isA<IconData>()));
    test(
      'AppIcons.camera existe',
      () => expect(AppIcons.camera, isA<IconData>()),
    );
    test(
      'AppIcons.filter existe',
      () => expect(AppIcons.filter, isA<IconData>()),
    );
    test(
      'AppIcons.search existe',
      () => expect(AppIcons.search, isA<IconData>()),
    );
    test(
      'AppIcons.close existe',
      () => expect(AppIcons.close, isA<IconData>()),
    );
    test('AppIcons.back existe', () => expect(AppIcons.back, isA<IconData>()));
    test('AppIcons.more existe', () => expect(AppIcons.more, isA<IconData>()));

    // ── Domain ───────────────────────────────────────────────────────────────

    test(
      'AppIcons.money existe',
      () => expect(AppIcons.money, isA<IconData>()),
    );
    test('AppIcons.bill existe', () => expect(AppIcons.bill, isA<IconData>()));
    test(
      'AppIcons.product existe',
      () => expect(AppIcons.product, isA<IconData>()),
    );
    test(
      'AppIcons.store existe',
      () => expect(AppIcons.store, isA<IconData>()),
    );
    test(
      'AppIcons.budget existe',
      () => expect(AppIcons.budget, isA<IconData>()),
    );
    test(
      'AppIcons.notification existe',
      () => expect(AppIcons.notification, isA<IconData>()),
    );
    test(
      'AppIcons.calendar existe',
      () => expect(AppIcons.calendar, isA<IconData>()),
    );
    test(
      'AppIcons.check existe',
      () => expect(AppIcons.check, isA<IconData>()),
    );
    test(
      'AppIcons.pending existe',
      () => expect(AppIcons.pending, isA<IconData>()),
    );
    test('AppIcons.late existe', () => expect(AppIcons.late, isA<IconData>()));
    test('AppIcons.info existe', () => expect(AppIcons.info, isA<IconData>()));
    test(
      'AppIcons.success existe',
      () => expect(AppIcons.success, isA<IconData>()),
    );
    test(
      'AppIcons.error existe',
      () => expect(AppIcons.error, isA<IconData>()),
    );
    test(
      'AppIcons.warning existe',
      () => expect(AppIcons.warning, isA<IconData>()),
    );

    // ── License / About ───────────────────────────────────────────────────────

    test(
      'AppIcons.about existe',
      () => expect(AppIcons.about, isA<IconData>()),
    );
    test(
      'AppIcons.openSource existe',
      () => expect(AppIcons.openSource, isA<IconData>()),
    );

    // ── 011 ───────────────────────────────────────────────────────────────────

    test(
      'AppIcons.stock existe',
      () => expect(AppIcons.stock, isA<IconData>()),
    );
    test(
      'AppIcons.checklist existe',
      () => expect(AppIcons.checklist, isA<IconData>()),
    );
    test(
      'AppIcons.lowStock existe',
      () => expect(AppIcons.lowStock, isA<IconData>()),
    );
    test(
      'AppIcons.economy existe',
      () => expect(AppIcons.economy, isA<IconData>()),
    );
    test(
      'AppIcons.widgetIcon existe',
      () => expect(AppIcons.widgetIcon, isA<IconData>()),
    );
    test('AppIcons.room existe', () => expect(AppIcons.room, isA<IconData>()));

    // ── SPEC-010 ─────────────────────────────────────────────────────────────

    test(
      'AppIcons.backup existe',
      () => expect(AppIcons.backup, isA<IconData>()),
    );
    test(
      'AppIcons.restore existe',
      () => expect(AppIcons.restore, isA<IconData>()),
    );
    test(
      'AppIcons.cloudBackup existe',
      () => expect(AppIcons.cloudBackup, isA<IconData>()),
    );
    test(
      'AppIcons.fileExport existe',
      () => expect(AppIcons.fileExport, isA<IconData>()),
    );
    test(
      'AppIcons.fileImport existe',
      () => expect(AppIcons.fileImport, isA<IconData>()),
    );
    test(
      'AppIcons.share existe',
      () => expect(AppIcons.share, isA<IconData>()),
    );
    test(
      'AppIcons.lockBackup existe',
      () => expect(AppIcons.lockBackup, isA<IconData>()),
    );
    test(
      'AppIcons.deleteForever existe',
      () => expect(AppIcons.deleteForever, isA<IconData>()),
    );
    test(
      'AppIcons.taskPreset existe',
      () => expect(AppIcons.taskPreset, isA<IconData>()),
    );
    test(
      'AppIcons.alreadyInRoutine existe',
      () => expect(AppIcons.alreadyInRoutine, isA<IconData>()),
    );
    test(
      'AppIcons.customizeDashboard existe',
      () => expect(AppIcons.customizeDashboard, isA<IconData>()),
    );
    test(
      'AppIcons.moveUp existe',
      () => expect(AppIcons.moveUp, isA<IconData>()),
    );
    test(
      'AppIcons.moveDown existe',
      () => expect(AppIcons.moveDown, isA<IconData>()),
    );
    test(
      'AppIcons.paste existe',
      () => expect(AppIcons.paste, isA<IconData>()),
    );
    test(
      'AppIcons.radioButtonChecked existe',
      () => expect(AppIcons.radioButtonChecked, isA<IconData>()),
    );
    test(
      'AppIcons.radioButtonOff existe',
      () => expect(AppIcons.radioButtonOff, isA<IconData>()),
    );

    // ── Architecture rule: features do not use Icons directly ─────────────

    test('Nenhum arquivo em lib/features/ importa Icons diretamente', () {
      final featuresDir = Directory('${Directory.current.path}/lib/features');

      // If directory does not exist yet, rule cannot be violated.
      if (!featuresDir.existsSync()) {
        return;
      }

      final dartFiles = featuresDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Detecta uso de Icons.<algo> sem passar por AppIcons
        if (content.contains(RegExp(r'(?<!App)Icons\.'))) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Os arquivos abaixo usam Icons. diretamente. '
            'Use AppIcons em vez disso:\n${violations.join('\n')}',
      );
    });
  });
}
