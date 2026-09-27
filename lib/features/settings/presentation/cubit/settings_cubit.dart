import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/store_settings_model.dart';
import '../../data/repositories/settings_repository.dart';
import 'settings_state.dart';

export 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsCubit(this.settingsRepository) : super(const SettingsInitial());

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await settingsRepository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> saveSettings(StoreSettingsModel settings) async {
    try {
      await settingsRepository.updateSettings(settings);
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
