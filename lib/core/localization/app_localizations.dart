import 'package:flutter/material.dart';
import 'ar.dart';
import 'en.dart';

/// App localizations handling English and Arabic dictionaries
class AppLocalizations {
  final Locale locale;
  static AppLocalizations? _current;

  AppLocalizations(this.locale) {
    _current = this;
  }

  static void setLocale(Locale locale) {
    _current = AppLocalizations(locale);
  }

  static AppLocalizations get current => _current ?? AppLocalizations(const Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': en,
    'ar': ar,
  };

  String translate(String key) {
    if (key.isEmpty) return '';
    final languageCode = locale.languageCode;
    final val = _localizedValues[languageCode]?[key] ?? _localizedValues['en']?[key];
    if (val != null && val.isNotEmpty) {
      return val;
    }

    // Never expose raw identifiers with underscores to the user in the UI.
    // Replace underscores with clean spaces and capitalize words.
    if (key.contains('_')) {
      final words = key.split('_');
      return words
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

/// String extension for resolving localized keys: 'dashboard'.tr
extension TransExtension on String {
  String get tr => AppLocalizations.current.translate(this);

  String trParams([Map<String, String>? params]) {
    String text = AppLocalizations.current.translate(this);
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }
    return text;
  }
}
