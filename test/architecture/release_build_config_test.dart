import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'Build and Release Configuration — CA-4.1, CA-4.2, CA-5.10 (RNF-004)',
    () {
      final gradleFile = File('android/app/build.gradle.kts');
      final deployWorkflowFile = File('.github/workflows/deploy.yml');
      final flutterWorkflowFile = File('.github/workflows/flutter.yml');

      test('build configuration files exist', () {
        expect(gradleFile.existsSync(), isTrue);
        expect(deployWorkflowFile.existsSync(), isTrue);
        expect(flutterWorkflowFile.existsSync(), isTrue);
      });

      test('CA-4.1: build.gradle.kts does not reference debug signing in release and throws GradleException without key', () {
        final content = gradleFile.readAsStringSync();

        // Does not reference signingConfigs.getByName("debug")
        expect(
          content.contains('signingConfigs.getByName("debug")'),
          isFalse,
          reason: 'Release must NEVER use debug key (CA-4.1).',
        );

        // Release block uses signingConfigs.getByName("release")
        expect(
          content.contains(
            'signingConfig = signingConfigs.getByName("release")',
          ),
          isTrue,
        );

        // Throws GradleException explaining absence of key.properties
        expect(
          content.contains('throw GradleException'),
          isTrue,
          reason:
              'Must throw GradleException if key.properties is not provided.',
        );
        expect(content.contains('key.properties'), isTrue);
      });

      test('CA-4.2: release enables obfuscation (isMinifyEnabled), resource shrinking (isShrinkResources) and deploy flags', () {
        final gradleContent = gradleFile.readAsStringSync();

        expect(
          gradleContent.contains('isMinifyEnabled = true'),
          isTrue,
          reason: 'isMinifyEnabled must be active in release (CA-4.2).',
        );

        expect(
          gradleContent.contains('isShrinkResources = true'),
          isTrue,
          reason: 'isShrinkResources must be active in release (CA-4.2).',
        );

        final deployContent = deployWorkflowFile.readAsStringSync();
        expect(
          deployContent.contains('--obfuscate'),
          isTrue,
          reason: 'deploy.yml must invoke build with --obfuscate (CA-4.2).',
        );
        expect(
          deployContent.contains('--split-debug-info'),
          isTrue,
          reason: 'deploy.yml must use --split-debug-info (CA-4.2).',
        );
      });

      test('CA-5.10 / RNF-004: APK CI validates 60 MB limit and generates ephemeral release keystore', () {
        final flutterContent = flutterWorkflowFile.readAsStringSync();

        // Limit of 60 MB per split APK (RNF-004)
        expect(flutterContent.contains(r'max=$((60 * 1024 * 1024))'), isTrue);

        // Ephemeral keystore generation with keytool to avoid using debug key
        expect(flutterContent.contains('keytool -genkeypair'), isTrue);
        expect(flutterContent.contains('upload-keystore.jks'), isTrue);
      });
    },
  );
}
