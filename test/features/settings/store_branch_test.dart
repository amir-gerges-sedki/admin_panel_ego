import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/settings/data/models/store_branch_model.dart';
import 'package:admin_panel_ego/features/settings/data/models/store_settings_model.dart';

void main() {
  group('StoreBranchModel & StoreSettingsModel Serialization', () {
    test('StoreBranchModel converts to and from json correctly', () {
      final branch = StoreBranchModel(
        id: 'branch_1',
        name: 'فرع المعادي',
        phone: '01012345678',
        address: 'شارع 9، المعادي',
        mapsUrl: 'https://maps.google.com/?q=29.9602,31.2568',
        latitude: 29.9602,
        longitude: 31.2568,
        isPrimary: true,
      );

      final json = branch.toJson();
      expect(json['id'], 'branch_1');
      expect(json['name'], 'فرع المعادي');
      expect(json['latitude'], 29.9602);
      expect(json['longitude'], 31.2568);
      expect(json['isPrimary'], true);

      final restored = StoreBranchModel.fromJson(json);
      expect(restored.id, branch.id);
      expect(restored.name, branch.name);
      expect(restored.phone, branch.phone);
      expect(restored.address, branch.address);
      expect(restored.mapsUrl, branch.mapsUrl);
      expect(restored.latitude, branch.latitude);
      expect(restored.longitude, branch.longitude);
      expect(restored.isPrimary, true);
    });

    test('StoreSettingsModel preserves branches in fromJson and toJson', () {
      final branch = StoreBranchModel(
        id: 'b1',
        name: 'فرع مدينة نصر',
        phone: '01122334455',
        address: 'شارع عباس العقاد',
        mapsUrl: 'https://maps.google.com/?q=30.0561,31.3301',
        latitude: 30.0561,
        longitude: 31.3301,
        isPrimary: false,
      );

      final settings = StoreSettingsModel(
        phoneNumber: '01000000000',
        whatsNumber: '01000000000',
        email: 'info@egostore.com',
        address: 'القاهرة، مصر',
        branches: [branch],
      );

      final json = settings.toJson();
      expect(json['branches'], isA<List>());
      expect((json['branches'] as List).length, 1);

      final restored = StoreSettingsModel.fromJson(json);
      expect(restored.branches.length, 1);
      expect(restored.branches.first.name, 'فرع مدينة نصر');
      expect(restored.branches.first.latitude, 30.0561);
      expect(restored.lowStockThreshold, 10);
    });

    test('StoreSettingsModel supports dynamic lowStockThreshold configuration', () {
      const settings = StoreSettingsModel(
        phoneNumber: '01000000000',
        whatsNumber: '01000000000',
        email: 'info@egostore.com',
        address: 'Cairo, Egypt',
        lowStockThreshold: 15,
      );

      final json = settings.toJson();
      expect(json['lowStockThreshold'], 15);

      final restored = StoreSettingsModel.fromJson(json);
      expect(restored.lowStockThreshold, 15);
    });
  });
}
