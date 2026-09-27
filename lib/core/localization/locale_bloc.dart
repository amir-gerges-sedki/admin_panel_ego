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
  @override
  List<Object?> get props => [locale];
}

// Bloc
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc() : super(const LocaleState(Locale('en'))) {
    AppLocalizations.setLocale(const Locale('en'));
    on<ChangeLocaleEvent>((event, emit) {
      AppLocalizations.setLocale(event.locale);
      emit(LocaleState(event.locale));
    });
  }

  void toggleLocale() {
    if (state.locale.languageCode == 'en') {
      add(const ChangeLocaleEvent(Locale('ar')));
    } else {
      add(const ChangeLocaleEvent(Locale('en')));
    }
  }
}
