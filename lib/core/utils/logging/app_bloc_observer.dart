import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// Global Bloc observer: any uncaught cubit/bloc error is persisted to the
/// single shared [AppLogger] (local store + live stream + App Logs UI)
/// with its stack trace. Register once in main() via
/// `Bloc.observer = AppBlocObserver();`.
///
/// This is a safety net only — expected failures (auth, database,
/// network) are logged explicitly at the repository/cubit layers with
/// full operation context.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.instance.error(
      message: '${bloc.runtimeType} uncaught error',
      category: LogCategory.bloc,
      event: 'BLOC_UNCAUGHT_ERROR',
      screen: bloc.runtimeType.toString(),
      operation: 'blocOnError',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
