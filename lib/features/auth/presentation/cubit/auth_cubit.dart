import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/supabase/supabase_config.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_with_facebook_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/resend_confirmation_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUsecase signInUsecase;
  final SignInWithGoogleUsecase signInWithGoogleUsecase;
  final SignInWithFacebookUsecase signInWithFacebookUsecase;
  final SignUpUsecase signUpUsecase;
  final SignOutUsecase signOutUsecase;
  final ResetPasswordUsecase resetPasswordUsecase;
  final ResendConfirmationUsecase resendConfirmationUsecase;
  final UpdatePasswordUsecase updatePasswordUsecase;
  final WatchAuthStateUsecase watchAuthStateUsecase;
  final GetCurrentUserUsecase getCurrentUserUsecase;

  AuthCubit({
    required this.signInUsecase,
    required this.signInWithGoogleUsecase,
    required this.signInWithFacebookUsecase,
    required this.signUpUsecase,
    required this.signOutUsecase,
    required this.resetPasswordUsecase,
    required this.resendConfirmationUsecase,
    required this.updatePasswordUsecase,
    required this.watchAuthStateUsecase,
    required this.getCurrentUserUsecase,
  }) : super(AuthInitial());

  StreamSubscription<UserEntity?>? _authSubscription;
  bool _listeningToAuthState = false;

  /// Subscribes to live Supabase auth-state changes (sign-in/out, token
  /// refresh, session expiry) so the app reacts without polling.
  ///
  /// Only genuine TRANSITIONS are emitted: if the state already reflects
  /// the event (e.g. an explicit sign-in just emitted [AuthAuthenticated]
  /// for the same user), the duplicate is skipped. Safe to call multiple
  /// times; the subscription is cancelled in [close].
  Future<void> listenToAuthState() async {
    if (_listeningToAuthState) return;
    _listeningToAuthState = true;

    try {
      final result = await watchAuthStateUsecase(const NoParams());
      result.fold(
        (error) {
          AppLogger.instance.error(
            message: 'Auth state subscription failed: $error',
            category: LogCategory.authentication,
            event: 'AUTH_STATE_SUBSCRIBE_FAILURE',
            screen: 'AuthCubit',
            operation: 'listenToAuthState',
          );
        },
        (stream) {
          _authSubscription = stream.listen(
            _onAuthStateEvent,
            onError: _onAuthStateError,
          );
        },
      );
    } catch (e, stackTrace) {
      // The stream source itself threw (e.g. Supabase unavailable):
      // log and continue without live updates rather than crashing.
      AppLogger.instance.error(
        message: 'Auth state subscription failed',
        category: LogCategory.authentication,
        event: 'AUTH_STATE_SUBSCRIBE_FAILURE',
        screen: 'AuthCubit',
        operation: 'listenToAuthState',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _onAuthStateEvent(UserEntity? user) {
    if (isClosed) return;
    if (user == null) {
      _onSignedOut();
      return;
    }
    final current = state;
    if (current is AuthAuthenticated) {
      if (current.user.id == user.id) return;
    }
    AppLogger.instance.info(
      message: 'Auth state changed: user signed in',
      category: LogCategory.authentication,
      event: 'AUTH_STATE_SIGNED_IN',
      screen: 'AuthCubit',
      operation: 'listenToAuthState',
    );
    emit(AuthAuthenticated(user));
  }

  void _onSignedOut() {
    final current = state;
    if (current is AuthUnauthenticated) return;
    if (current is AuthInitial) return;
    AppLogger.instance.info(
      message: 'Auth state changed: user signed out',
      category: LogCategory.authentication,
      event: 'AUTH_STATE_SIGNED_OUT',
      screen: 'AuthCubit',
      operation: 'listenToAuthState',
    );
    emit(AuthUnauthenticated());
  }

  void _onAuthStateError(Object error, StackTrace stackTrace) {
    AppLogger.instance.error(
      message: 'Auth state stream error',
      category: LogCategory.authentication,
      event: 'AUTH_STATE_STREAM_FAILURE',
      screen: 'AuthCubit',
      operation: 'listenToAuthState',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    final result = await getCurrentUserUsecase(const NoParams());

    result.fold((error) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());

    final result = await signInUsecase(
      SignInParams(email: email, password: password),
    );

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Sign-in operation failed: $error',
        category: LogCategory.authentication,
        event: 'SIGN_IN_OPERATION_FAILURE',
        screen: 'AuthCubit',
        operation: 'signIn',
      );
      if (error.contains('confirm your email') ||
          error.contains('confirm your email')) {
        emit(AuthEmailConfirmationRequired(email));
      } else {
        emit(AuthError(error));
      }
    }, (user) => emit(AuthAuthenticated(user)));
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    emit(AuthLoading());

    AppLogger.instance.info(
      message: 'Create account operation started',
      category: LogCategory.authentication,
      event: 'CREATE_ACCOUNT_START',
      screen: 'AuthCubit',
      operation: 'signUp',
      context: const {
        // The redirect target itself (no secrets, no tokens).
        'emailRedirectTo': SupabaseConfig.authRedirectTo,
      },
    );

    final result = await signUpUsecase(
      SignUpParams(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        emailRedirectTo: SupabaseConfig.authRedirectTo,
      ),
    );

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Create account operation failed: $error',
          category: LogCategory.authentication,
          event: 'CREATE_ACCOUNT_FAILURE',
          screen: 'AuthCubit',
          operation: 'signUp',
        );
        emit(AuthError(error));
      },
      (user) {
        AppLogger.instance.info(
          message: 'Create account operation succeeded',
          category: LogCategory.authentication,
          event: 'CREATE_ACCOUNT_SUCCESS',
          screen: 'AuthCubit',
          operation: 'signUp',
        );
        emit(AuthEmailConfirmationRequired(email));
      },
    );
  }

  /// Google OAuth sign-in. The provider opens in a browser and returns
  /// through the app deep link; success lands in [checkAuthStatus].
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    AppLogger.instance.info(
      message: 'Google sign-in operation started',
      category: LogCategory.authentication,
      event: 'GOOGLE_SIGN_IN_START',
      screen: 'AuthCubit',
      operation: 'signInWithGoogle',
    );

    final result = await signInWithGoogleUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Google sign-in operation failed: $error',
        category: LogCategory.authentication,
        event: 'GOOGLE_SIGN_IN_OPERATION_FAILURE',
        screen: 'AuthCubit',
        operation: 'signInWithGoogle',
      );
      emit(AuthError(error));
    }, (_) => checkAuthStatus());
  }

  /// Facebook OAuth sign-in. Same deep-link return path as Google.
  Future<void> signInWithFacebook() async {
    emit(AuthLoading());

    AppLogger.instance.info(
      message: 'Facebook sign-in operation started',
      category: LogCategory.authentication,
      event: 'FACEBOOK_SIGN_IN_START',
      screen: 'AuthCubit',
      operation: 'signInWithFacebook',
    );

    final result = await signInWithFacebookUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Facebook sign-in operation failed: $error',
        category: LogCategory.authentication,
        event: 'FACEBOOK_SIGN_IN_OPERATION_FAILURE',
        screen: 'AuthCubit',
        operation: 'signInWithFacebook',
      );
      emit(AuthError(error));
    }, (_) => checkAuthStatus());
  }

  Future<void> signOut() async {
    emit(AuthLoading());

    final result = await signOutUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Sign-out operation failed: $error',
        category: LogCategory.authentication,
        event: 'SIGN_OUT_OPERATION_FAILURE',
        screen: 'AuthCubit',
        operation: 'signOut',
      );
      emit(AuthError(error));
    }, (_) => emit(AuthUnauthenticated()));
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());

    final result = await resetPasswordUsecase(email);

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Password reset operation failed: $error',
        category: LogCategory.authentication,
        event: 'RESET_PASSWORD_OPERATION_FAILURE',
        screen: 'AuthCubit',
        operation: 'resetPassword',
      );
      emit(AuthError(error));
    }, (_) => emit(AuthPasswordResetSent(email)));
  }

  /// Resends the signup confirmation email. Never logs the email body or
  /// any credential — only the operation outcome.
  Future<void> resendConfirmation(String email) async {
    AppLogger.instance.info(
      message: 'Resend confirmation started',
      category: LogCategory.authentication,
      event: 'RESEND_CONFIRMATION_START',
      screen: 'AuthCubit',
      operation: 'resendConfirmation',
    );

    final result = await resendConfirmationUsecase(email);

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Resend confirmation failed: $error',
          category: LogCategory.authentication,
          event: 'RESEND_CONFIRMATION_FAILURE',
          screen: 'AuthCubit',
          operation: 'resendConfirmation',
        );
        emit(AuthError(error));
      },
      (_) {
        AppLogger.instance.info(
          message: 'Resend confirmation succeeded',
          category: LogCategory.authentication,
          event: 'RESEND_CONFIRMATION_SUCCESS',
          screen: 'AuthCubit',
          operation: 'resendConfirmation',
        );
        emit(AuthConfirmationResent(email));
      },
    );
  }

  /// Updates the password. The new password value is never logged.
  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());

    final result = await updatePasswordUsecase(newPassword);

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Password update failed',
          category: LogCategory.authentication,
          event: 'UPDATE_PASSWORD_FAILURE',
          screen: 'AuthCubit',
          operation: 'updatePassword',
        );
        emit(AuthError(error));
      },
      (_) {
        AppLogger.instance.info(
          message: 'Password updated successfully',
          category: LogCategory.authentication,
          event: 'UPDATE_PASSWORD_SUCCESS',
          screen: 'AuthCubit',
          operation: 'updatePassword',
        );
        emit(AuthPasswordUpdated());
      },
    );
  }

  void clearError() {
    if (state is AuthError) {
      emit(AuthUnauthenticated());
    }
  }
}
