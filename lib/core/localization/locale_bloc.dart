import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_localizations.dart';

// Events
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object?> get props => [];
}

class ChangeLocaleEvent extends LocaleEvent {
  final Locale locale;
  const ChangeLocaleEvent(this.locale);
  @override
  List<Object?> get props => [locale];
}

// States
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  @override
  List<Object?> get props => [locale];
}

// Bloc
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc() : super(const LocaleState(Locale('ar'))) {
    AppLocalizations.setLocale(const Locale('ar'));
    on<ChangeLocaleEvent>((event, emit) {
      AppLocalizations.setLocale(event.locale);
      emit(LocaleState(event.locale));
    });
  }

  void toggleLocale() {
    if (state.locale.languageCode == 'ar') {
      add(const ChangeLocaleEvent(Locale('en')));
    } else {
      add(const ChangeLocaleEvent(Locale('ar')));
    }
  }

  void setLocale(Locale locale) {
    add(ChangeLocaleEvent(locale));
  }
}
