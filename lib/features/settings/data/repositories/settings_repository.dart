import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/store_settings_model.dart';

abstract class SettingsRepository {
  Future<StoreSettingsModel> getSettings();
  Future<void> updateSettings(StoreSettingsModel settings);
}

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<StoreSettingsModel> getSettings() async {
    try {
      final doc = await FirebaseService.contactInfoDoc.get();
      if (doc.exists && doc.data() != null) {
        return StoreSettingsModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    return const StoreSettingsModel(
      phoneNumber: '',
      whatsNumber: '',
      email: '',
      address: '',
      enforceAgeVerification: true,
      showNicotineWarningBanner: true,
      flatDeliveryFee: 60.0,
      freeShippingThreshold: 2000.0,
    );
  }

  @override
  Future<void> updateSettings(StoreSettingsModel settings) async {
    await FirebaseService.contactInfoDoc.set(settings.toJson(), SetOptions(merge: true));
  }
}
