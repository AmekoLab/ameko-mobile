import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/utils/app_logger.dart';

/// Observes all BLoC events, state transitions, and errors for diagnostics.
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    appLogger.d('BLoC created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    appLogger.d('📩 ${bloc.runtimeType} → Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    appLogger.d(
      '🔄 ${bloc.runtimeType}\n'
      '  Current: ${change.currentState}\n'
      '  Next:    ${change.nextState}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    appLogger.d('⚡ ${bloc.runtimeType} Transition: ${transition.event}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    appLogger.e(
      '❌ ${bloc.runtimeType} Error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    appLogger.d('BLoC closed: ${bloc.runtimeType}');
  }
}
