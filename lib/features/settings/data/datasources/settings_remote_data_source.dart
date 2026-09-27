import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/store_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<StoreSettingsModel?> getSettings();
  Future<void> updateSettings(StoreSettingsModel settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('Settings').doc('store_settings');

  @override
  Future<StoreSettingsModel?> getSettings() async {
    try {
      final doc = await _settingsDoc.get();
      if (doc.exists && doc.data() != null) {
        return StoreSettingsModel.fromJson(doc.data()!);
      }
    } catch (_) {
      // Return null on failure
    }

    return null;
  }

  @override
  Future<void> updateSettings(StoreSettingsModel settings) async {
    // Single source of truth: write to 'Settings' collection
    await _settingsDoc.set(settings.toJson(), SetOptions(merge: true));
  }
}
