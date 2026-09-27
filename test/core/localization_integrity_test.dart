import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/localization/en.dart';
import 'package:admin_panel_ego/core/localization/ar.dart';

void main() {
  group('Localization Integrity Tests', () {
    test('en and ar dictionaries should be non-empty', () {
      expect(en.isNotEmpty, isTrue);
      expect(ar.isNotEmpty, isTrue);
    });

    test('en and ar dictionaries should have exact symmetry or report differences', () {
      final enKeys = en.keys.toSet();
      final arKeys = ar.keys.toSet();

      final missingInAr = enKeys.difference(arKeys);
      final missingInEn = arKeys.difference(enKeys);


      expect(missingInAr.isEmpty, isTrue,
          reason: 'Missing AR keys: $missingInAr');
      expect(missingInEn.isEmpty, isTrue,
          reason: 'Missing EN keys: $missingInEn');
    });

    test('no empty values in en and ar', () {
      for (final entry in en.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: 'EN key "${entry.key}" has empty value');
      }
      for (final entry in ar.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: 'AR key "${entry.key}" has empty value');
      }
    });
  });
}
