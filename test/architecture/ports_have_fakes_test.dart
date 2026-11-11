/// T-21: Testes de arquitetura — toda porta tem fake correspondente
/// (004-testing.md §3)
///
/// Varre lib/ em busca de `abstract class ...Port` e verifica que existe
/// um arquivo em test/fakes/ correspondente.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ports have fakes — 004-testing §3', () {
    test('toda abstract class *Port em lib/ tem fake em test/fakes/', () {
      final ports = _discoverPorts('lib');
      final fakeFiles = _discoverFakeFiles('test/fakes');

      final violations = <String>[];
      for (final port in ports) {
        // Converte NomePort → fake_nome.dart ou fake_nome_port.dart
        final expected = _expectedFakeName(port.className);
        final hasMatchingFake = fakeFiles.any(
          (f) => f.toLowerCase().contains(expected.toLowerCase()),
        );
        if (!hasMatchingFake) {
          violations.add(
            '${port.filePath}: ${port.className} → esperado fake com '
            "'$expected' em test/fakes/",
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Portas sem fake correspondente:\n${violations.join('\n')}',
      );
    });

    // ---------------------------------------------------------------------------
    // Fixtures do detector
    // ---------------------------------------------------------------------------
    test('fixture: detecta abstract class ClockPort', () {
      const code = '''
abstract class ClockPort {
  DateTime nowUtc();
}
''';
      final ports = _parsePortsFromContent(
        code,
        'lib/core/time/clock_port.dart',
      );
      expect(ports.map((p) => p.className), contains('ClockPort'));
    });

    test('fixture: does not detect concrete class as Port', () {
      const code = '''
class ClockImpl implements ClockPort {
  DateTime nowUtc() => DateTime.now().toUtc();
}
''';
      final ports = _parsePortsFromContent(
        code,
        'lib/core/time/clock_impl.dart',
      );
      expect(ports, isEmpty);
    });

    test(
      'fixture: Clock (abstract class without Port in name) is not detected',
      () {
        // The convention is *Port — Clock is base type, not infra port.
        // Detection is by 'Port' suffix.
        const code = '''
abstract class Clock {
  DateTime nowUtc();
}
''';
        final ports = _parsePortsFromContent(code, 'lib/core/time/clock.dart');
        expect(
          ports,
          isEmpty,
          reason: 'Clock without Port suffix should not be detected',
        );
      },
    );

    test('fake_clock.dart cobre Clock (Port bem-conhecido)', () {
      // Well-known ports from 004-testing §3 that already have fakes:
      final knownFakes = Directory('test/fakes').existsSync()
          ? Directory('test/fakes')
                .listSync()
                .whereType<File>()
                .map((f) => f.uri.pathSegments.last)
                .toList()
          : <String>[];

      expect(
        knownFakes.any((f) => f.contains('fake_clock') || f.contains('clock')),
        isTrue,
        reason: 'FakeClock not found in test/fakes/',
      );

      expect(
        knownFakes.any(
          (f) => f.contains('sequential_id') || f.contains('id_generator'),
        ),
        isTrue,
        reason: 'SequentialIdGenerator not found in test/fakes/',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Tipos e helpers
// ---------------------------------------------------------------------------

final class _PortInfo {
  const _PortInfo({required this.filePath, required this.className});
  final String filePath;
  final String className;
}

List<_PortInfo> _discoverPorts(String directory) {
  final result = <_PortInfo>[];
  for (final file in _findDartFiles(directory)) {
    final content = file.readAsStringSync();
    final ports = _parsePortsFromContent(content, file.path);
    result.addAll(ports);
  }
  return result;
}

List<_PortInfo> _parsePortsFromContent(String content, String filePath) {
  final result = <_PortInfo>[];
  // Detecta: abstract class FooPort ou abstract interface class FooPort
  final pattern = RegExp(
    r'^\s*abstract\s+(?:interface\s+)?class\s+(\w+Port)\b',
    multiLine: true,
  );
  for (final match in pattern.allMatches(content)) {
    result.add(_PortInfo(filePath: filePath, className: match.group(1)!));
  }
  return result;
}

List<String> _discoverFakeFiles(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .toList();
}

/// Converte NomeDoPort → nome_do esperado no arquivo de fake.
/// Ex.: CalendarGatewayPort → calendar_gateway, TextRecognizerPort → text_recognizer
String _expectedFakeName(String className) {
  // Remove sufixo 'Port'
  var name = className.endsWith('Port')
      ? className.substring(0, className.length - 4)
      : className;
  // camelCase → snake_case
  name = name
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
  return name;
}

Iterable<File> _findDartFiles(String directory) sync* {
  final dir = Directory(directory);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart') &&
        !entity.path.endsWith('.freezed.dart')) {
      yield entity;
    }
  }
}
