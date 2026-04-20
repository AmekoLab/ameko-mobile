import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ameko_app/core/services/storage_service.dart';

// Events
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object?> get props => [];
}

class LoadLocale extends LocaleEvent {}

class ChangeLocale extends LocaleEvent {
  final Locale locale;
  const ChangeLocale(this.locale);
  @override
  List<Object?> get props => [locale];
}

// State
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState(this.locale);
  @override
  List<Object?> get props => [locale];
}

// Bloc
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final StorageService _storage;
  static const _localeKey = 'app_locale';

  LocaleBloc(this._storage) : super(const LocaleState(Locale('en'))) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  void _onLoadLocale(LoadLocale event, Emitter<LocaleState> emit) {
    final languageCode = _storage.getString(_localeKey);
    if (languageCode != null) {
      emit(LocaleState(Locale(languageCode)));
    } else {
      // Default to system locale if possible, or 'en'
      final systemLocale = PlatformDispatcher.instance.locale.languageCode;
      if (systemLocale == 'vi' || systemLocale == 'en') {
        emit(LocaleState(Locale(systemLocale)));
      }
    }
  }

  Future<void> _onChangeLocale(ChangeLocale event, Emitter<LocaleState> emit) async {
    await _storage.setString(_localeKey, event.locale.languageCode);
    emit(LocaleState(event.locale));
  }
}
