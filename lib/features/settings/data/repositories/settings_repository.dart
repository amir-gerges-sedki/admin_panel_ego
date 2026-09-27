import 'package:flutter/foundation.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/governorate_delivery_model.dart';
import '../models/store_settings_model.dart';

abstract class SettingsRepository {
  Future<StoreSettingsModel> getSettings();
  Future<void> updateSettings(StoreSettingsModel settings);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({SettingsRemoteDataSource? remoteDataSource})
      : remoteDataSource =
            remoteDataSource ?? SettingsRemoteDataSourceImpl();

  @override
  Future<StoreSettingsModel> getSettings() async {
    try {
      final settings = await remoteDataSource.getSettings();
      if (settings != null) {
        return settings;
      }
    } catch (e) {
      debugPrint('Firestore settings fetch note: $e');
    }

    return StoreSettingsModel(
      phoneNumber: '',
      whatsNumber: '',
      email: '',
      address: '',
      enforceAgeVerification: true,
      showNicotineWarningBanner: true,
      flatDeliveryFee: 0.0,
      freeShippingThreshold: 0.0,
      estimatedDeliveryTime: '24-48 Hours',
      governorates: GovernorateDeliveryModel.defaultGovernorates(),
    );
  }

  @override
  Future<void> updateSettings(StoreSettingsModel settings) async {
    await remoteDataSource.updateSettings(settings);
  }
}
