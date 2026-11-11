import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CA-3.1 / RN-413: Block automatic backup and transfer on Android', () {
    const manifestPath = 'android/app/src/main/AndroidManifest.xml';
    const rulesPath = 'android/app/src/main/res/xml/data_extraction_rules.xml';

    test('AndroidManifest.xml desativa allowBackup, fullBackupContent e aponta dataExtractionRules', () {
      final manifestFile = File(manifestPath);
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'AndroidManifest.xml deve existir',
      );

      final content = manifestFile.readAsStringSync();

      expect(
        content.contains('android:allowBackup="false"'),
        isTrue,
        reason: 'AndroidManifest.xml deve conter android:allowBackup="false" (RN-413)',
      );

      expect(
        content.contains('android:fullBackupContent="false"'),
        isTrue,
        reason: 'AndroidManifest.xml deve conter android:fullBackupContent="false" (RN-413)',
      );

      expect(
        content.contains(
          'android:dataExtractionRules="@xml/data_extraction_rules"',
        ),
        isTrue,
        reason: 'AndroidManifest.xml deve apontar android:dataExtractionRules="@xml/data_extraction_rules" (RN-413)',
      );
    });

    test('data_extraction_rules.xml exclui cloud-backup e device-transfer completamente', () {
      final rulesFile = File(rulesPath);
      expect(
        rulesFile.existsSync(),
        isTrue,
        reason: 'data_extraction_rules.xml deve existir',
      );

      final content = rulesFile.readAsStringSync();

      expect(content.contains('<data-extraction-rules>'), isTrue);
      expect(content.contains('<cloud-backup>'), isTrue);
      expect(content.contains('<device-transfer>'), isTrue);

      // Garante que exclui raiz em cloud-backup e device-transfer
      final cloudBackupMatch = RegExp(
        r'<cloud-backup>[\s\S]*?<exclude\s+path="\."\s*\/>[\s\S]*?<\/cloud-backup>',
      );
      expect(
        cloudBackupMatch.hasMatch(content),
        isTrue,
        reason: 'cloud-backup deve conter <exclude path="." />',
      );

      final deviceTransferMatch = RegExp(
        r'<device-transfer>[\s\S]*?<exclude\s+path="\."\s*\/>[\s\S]*?<\/device-transfer>',
      );
      expect(
        deviceTransferMatch.hasMatch(content),
        isTrue,
        reason: 'device-transfer deve conter <exclude path="." />',
      );
    });
  });
}
