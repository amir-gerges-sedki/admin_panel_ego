import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/settings/data/models/store_settings_model.dart';

void main() {
  group('StoreSettingsModel - Smoking Cessation Program Settings', () {
    test('Default constructor sets enableSmokingCessationProgram to true', () {
      final settings = StoreSettingsModel(
        phoneNumber: '01000000000',
        whatsNumber: '01100000000',
        email: 'store@example.com',
        address: 'Cairo, Egypt',
      );

      expect(settings.enableSmokingCessationProgram, isTrue);
      expect(settings.cessationDiscountPercent, 10.0);
      expect(settings.defaultCigarettePackPrice, 90.0);
    });

    test('fromJson and toJson correctly roundtrip disabled cessation program', () {
      final json = {
        'phoneNumber': '01000000000',
        'whatsNumber': '01100000000',
        'enableSmokingCessationProgram': false,
        'cessationDiscountPercent': 15.0,
        'defaultCigarettePackPrice': 100.0,
      };

      final settings = StoreSettingsModel.fromJson(json);
      expect(settings.enableSmokingCessationProgram, isFalse);
      expect(settings.cessationDiscountPercent, 15.0);
      expect(settings.defaultCigarettePackPrice, 100.0);

      final exported = settings.toJson();
      expect(exported['enableSmokingCessationProgram'], isFalse);
      expect(exported['cessationDiscountPercent'], 15.0);
      expect(exported['defaultCigarettePackPrice'], 100.0);
    });
  });
}
