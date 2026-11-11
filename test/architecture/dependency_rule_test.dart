/// T-19: Architecture test — dependency rule (CA-4.1)
///
/// Verifies that files in lib/features/*/domain/ DO NOT import:
///   - package:flutter/
///   - package:drift/
///   - dart:io
///   - lib/data/
///
/// Also verifies that features do not import internal files of other features.
///
/// The test operates on actual source code, not at runtime — it is a simple
/// static analyzer based on regex over .dart files in lib/ folder.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dependency rule — CA-4.1 (Article IV, RN-004)', () {
    const libPath = 'lib';

    // ---------------------------------------------------------------------------
    // INTENTIONALLY ERRONEOUS code fixtures (testing the test)
    // ---------------------------------------------------------------------------
    test('fixture: domain file with Flutter import is detected', () {
      const fakeCode = '''
import 'package:flutter/material.dart';
class MyDomainClass {}
''';
      final violations = _findForbiddenImports(
        content: fakeCode,
        filePath: 'lib/features/x/domain/my_class.dart',
        forbiddenPatterns: _domainForbiddenPatterns,
      );
      expect(
        violations,
        isNotEmpty,
        reason: 'Deveria detectar import Flutter em domain/',
      );
    });

    test('fixture: pure domain file produces no violation', () {
      const fakeCode = '''
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/money/money.dart';
class MyDomainClass {}
''';
      final violations = _findForbiddenImports(
        content: fakeCode,
        filePath: 'lib/features/x/domain/my_class.dart',
        forbiddenPatterns: _domainForbiddenPatterns,
      );
      expect(
        violations,
        isEmpty,
        reason: 'Core imports are allowed in domain/',
      );
    });

    test(
      'fixture: feature importing internal file of another feature is detected',
      () {
        const fakeCode = '''
import 'package:my_sweet_home/features/products/data/product_dao.dart';
class MyClass {}
''';
        final violations = _findCrossFeatureImports(
          content: fakeCode,
          filePath: 'lib/features/expenses/domain/expense_service.dart',
        );
        expect(
          violations,
          isNotEmpty,
          reason: 'Cross-feature import direto deve ser detectado',
        );
      },
    );

    // ---------------------------------------------------------------------------
    // Testes reais sobre lib/
    // ---------------------------------------------------------------------------
    test('domain/ does not import Flutter, Drift, dart:io, or data/', () {
      final domainFiles = _findDartFiles(libPath)
          .where((f) => f.path.replaceAll('\\', '/').contains('/domain/'))
          .toList();

      final violations = <String>[];
      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        final found = _findForbiddenImports(
          content: content,
          filePath: file.path,
          forbiddenPatterns: _domainForbiddenPatterns,
        );
        violations.addAll(found);
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Files in domain/ violate dependency rule:\n'
            '${violations.join('\n')}',
      );
    });

    test('presentation/ does not import data/', () {
      final presentationFiles = _findDartFiles(libPath)
          .where((f) => f.path.replaceAll('\\', '/').contains('/presentation/'))
          .toList();

      final violations = <String>[];
      for (final file in presentationFiles) {
        final content = file.readAsStringSync();
        final found = _findForbiddenImports(
          content: content,
          filePath: file.path,
          forbiddenPatterns: _presentationForbiddenPatterns,
        );
        violations.addAll(found);
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Files in presentation/ violate dependency rule:\n'
            '${violations.join('\n')}',
      );
    });

    test('features do not import internal files of other features', () {
      final featureFiles = _findDartFiles('$libPath/features').toList();

      final violations = <String>[];
      for (final file in featureFiles) {
        final content = file.readAsStringSync();
        final found = _findCrossFeatureImports(
          content: content,
          filePath: file.path,
        );
        violations.addAll(found);
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Imports cruzados entre features detectados:\n'
            '${violations.join('\n')}',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Prohibited patterns
// ---------------------------------------------------------------------------

/// Imports proibidos em `domain/`.
const _domainForbiddenPatterns = [
  r"import 'package:flutter/",
  r'import "package:flutter/',
  r"import 'package:drift/",
  r'import "package:drift/',
  r"import 'dart:io'",
  r'import "dart:io"',
  r"import 'dart:html'",
  r"import 'package:my_sweet_home/.*/data/",
];

/// Prohibited imports in `presentation/` (cannot access data/ directly).
const _presentationForbiddenPatterns = [
  r"import 'package:my_sweet_home/.*/data/(?!(adapters|.*provider))",
  r'import "package:my_sweet_home/.*/data/(?!(adapters|.*provider))',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _findForbiddenImports({
  required String content,
  required String filePath,
  required List<String> forbiddenPatterns,
}) {
  final violations = <String>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('import ')) continue;
    for (final pattern in forbiddenPatterns) {
      if (RegExp(pattern).hasMatch(line)) {
        violations.add('$filePath:${i + 1}: $line');
      }
    }
  }
  return violations;
}

List<String> _findCrossFeatureImports({
  required String content,
  required String filePath,
}) {
  // Dependency matrix declared in 001-architecture.md §4
  const allowedDependencies = <String, Set<String>>{
    'products': {},
    'prices': {'products', 'expenses'},
    'shopping': {'products', 'prices'},
    'expenses': {},
    'bills': {'expenses'},
    'tasks': {},
    'recipes': {'products', 'shopping', 'prices'},
    'ocr': {'products', 'prices', 'expenses', 'shopping'},
    'backup': {
      'products',
      'prices',
      'shopping',
      'expenses',
      'bills',
      'tasks',
      'recipes',
      'ocr',
      'extras',
    },
    'extras': {
      'products',
      'prices',
      'shopping',
      'expenses',
      'bills',
      'tasks',
      'recipes',
    },
    'onboarding': {'mascot', 'task_presets'},
    'mascot': {},
    'task_presets': {},
  };

  // Extrai o nome da feature atual do path
  final normalizedPath = filePath.replaceAll('\\', '/');
  final featureMatch = RegExp(r'lib/features/([^/]+)/')
      .firstMatch(normalizedPath);
  if (featureMatch == null) return [];
  final currentFeature = featureMatch.group(1)!;
  final allowed = allowedDependencies[currentFeature] ?? {};

  final violations = <String>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('import ')) continue;

    // Detects import from features/ that is neither current feature nor allowed dependency
    final match = RegExp(
      r'''import ['"]package:my_sweet_home/features/([^/'"]+)/''',
    ).firstMatch(line);
    if (match != null) {
      final importedFeature = match.group(1)!;
      if (importedFeature != currentFeature &&
          !allowed.contains(importedFeature)) {
        violations.add(
          '$filePath:${i + 1}: cross-feature import '
          '($currentFeature → $importedFeature): $line',
        );
      }
    }
  }
  return violations;
}

Iterable<File> _findDartFiles(String directory) sync* {
  final dir = Directory(directory);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}
