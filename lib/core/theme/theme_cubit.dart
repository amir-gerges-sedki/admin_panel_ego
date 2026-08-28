import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  bool get isDarkMode => themeMode == ThemeMode.dark;

  @override
  List<Object?> get props => [themeMode];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(ThemeMode.dark));

  void toggleTheme() {
    if (state.themeMode == ThemeMode.dark) {
      emit(const ThemeState(ThemeMode.light));
    } else {
      emit(const ThemeState(ThemeMode.dark));
    }
  }

  void setTheme(ThemeMode mode) {
    emit(ThemeState(mode));
  }
}
