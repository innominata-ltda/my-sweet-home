import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations ARB parity', () {
    test('app_pt.arb and app_en.arb have identical message keys', () {
      final ptFile = File('lib/app/l10n/app_pt.arb');
      final enFile = File('lib/app/l10n/app_en.arb');

      expect(ptFile.existsSync(), isTrue);
      expect(enFile.existsSync(), isTrue);

      final ptMap =
          jsonDecode(ptFile.readAsStringSync()) as Map<String, dynamic>;
      final enMap =
          jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

      final ptKeys = ptMap.keys.where((k) => !k.startsWith('@')).toSet();
      final enKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();

      expect(
        enKeys.difference(ptKeys),
        isEmpty,
        reason: 'Keys present in app_en.arb but missing in app_pt.arb',
      );
      expect(
        ptKeys.difference(enKeys),
        isEmpty,
        reason: 'Keys present in app_pt.arb but missing in app_en.arb',
      );
    });

    test('supportedLocales includes pt and en', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      expect(codes, containsAll(<String>['pt', 'en']));
    });

    test('lookupAppLocalizations resolves both pt and en', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(pt.expensesTitle, isNotEmpty);
      expect(en.expensesTitle, isNotEmpty);
      expect(pt.expensesTitle, isNot(equals(en.expensesTitle)));
    });
  });
}
