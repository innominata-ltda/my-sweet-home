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

      // Ensure root path is excluded with explicit domain attributes in cloud-backup and device-transfer
      const requiredDomains = [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
      ];
      for (final domain in requiredDomains) {
        final cloudBackupMatch = RegExp(
          '<cloud-backup>[\\s\\S]*?<exclude\\s+domain="$domain"\\s+path="\\."\\s*\\/>[\\s\\S]*?<\\/cloud-backup>',
        );
        expect(
          cloudBackupMatch.hasMatch(content),
          isTrue,
          reason:
              'cloud-backup must contain <exclude domain="$domain" path="." /> (RN-413)',
        );

        final deviceTransferMatch = RegExp(
          '<device-transfer>[\\s\\S]*?<exclude\\s+domain="$domain"\\s+path="\\."\\s*\\/>[\\s\\S]*?<\\/device-transfer>',
        );
        expect(
          deviceTransferMatch.hasMatch(content),
          isTrue,
          reason:
              'device-transfer must contain <exclude domain="$domain" path="." /> (RN-413)',
        );
      }
    });
  });
}
