import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/core/utils/logging/operation_logger.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/resend_confirmation_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_with_facebook_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:t_store/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';

class MockSignInUsecase extends Mock implements SignInUsecase {}

class MockSignInWithGoogleUsecase extends Mock
    implements SignInWithGoogleUsecase {}

class MockSignInWithFacebookUsecase extends Mock
    implements SignInWithFacebookUsecase {}

class MockSignUpUsecase extends Mock implements SignUpUsecase {}

class MockSignOutUsecase extends Mock implements SignOutUsecase {}

class MockResetPasswordUsecase extends Mock implements ResetPasswordUsecase {}

class MockResendConfirmationUsecase extends Mock
    implements ResendConfirmationUsecase {}

class MockUpdatePasswordUsecase extends Mock implements UpdatePasswordUsecase {}

class MockWatchAuthStateUsecase extends Mock
    implements WatchAuthStateUsecase {}

class MockGetCurrentUserUsecase extends Mock implements GetCurrentUserUsecase {}

class FakeSignUpParams extends Fake implements SignUpParams {}

class FakeNoParams extends Fake implements NoParams {}

/// Regression test for the reported runtime failure:
///
/// Create Account tapped → Supabase returns
/// "Database error saving new user" → only a red snackbar appeared
/// while App Logs stayed empty.
///
/// Contract under test: a use-case/repository failure MUST be logged
/// (persisted + live stream) AND still surface the user-facing error.
void main() {
  late AuthCubit authCubit;
  late MockSignUpUsecase mockSignUpUsecase;

  setUpAll(() {
    registerFallbackValue(FakeSignUpParams());
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockSignUpUsecase = MockSignUpUsecase();
    authCubit = AuthCubit(
      signInUsecase: MockSignInUsecase(),
      signInWithGoogleUsecase: MockSignInWithGoogleUsecase(),
      signInWithFacebookUsecase: MockSignInWithFacebookUsecase(),
      signUpUsecase: mockSignUpUsecase,
      signOutUsecase: MockSignOutUsecase(),
      resetPasswordUsecase: MockResetPasswordUsecase(),
      resendConfirmationUsecase: MockResendConfirmationUsecase(),
      updatePasswordUsecase: MockUpdatePasswordUsecase(),
      watchAuthStateUsecase: MockWatchAuthStateUsecase(),
      getCurrentUserUsecase: MockGetCurrentUserUsecase(),
    );
  });

  tearDown(() {
    authCubit.close();
  });

  // Mirrors the real Supabase failure string from the bug report.
  const dbFailure = 'Database error saving new user';

  group('Create account failure logging', () {
    blocTest<AuthCubit, AuthState>(
      'emits AuthError so the user-facing snackbar still shows',
      build: () {
        when(
          () => mockSignUpUsecase(any()),
        ).thenAnswer((_) async => const Left(dbFailure));
        return authCubit;
      },
      act: (cubit) => cubit.signUp(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    test(
      'failure is logged, persisted, and published on the live stream',
      () async {
        when(
          () => mockSignUpUsecase(any()),
        ).thenAnswer((_) async => const Left(dbFailure));

        final streamExpectation = expectLater(
          AppLogger.instance.logStream,
          emitsThrough(
            isA<AppLogEntry>()
                .having((e) => e.level, 'level', LogLevel.error)
                .having(
                  (e) => e.category,
                  'category',
                  LogCategory.authentication,
                )
                .having((e) => e.operation, 'operation', 'signUp')
                .having((e) => e.event, 'event', 'CREATE_ACCOUNT_FAILURE'),
          ),
        );

        await authCubit.signUp(
          email: 'new@example.com',
          password: 'password123',
          fullName: 'New User',
        );
        await streamExpectation;

        // Persisted: searchable in App Logs history after the fact.
        final persisted = AppLogger.instance.searchLogs(
          'Create account operation failed',
        );
        expect(persisted, isNotEmpty);
        expect(persisted.last.operation, 'signUp');
        expect(persisted.last.level, LogLevel.error);

        // Copyable: full diagnostic report renders from the entry.
        final report = AppLogger.instance.formatDiagnosticReport(
          persisted.last,
        );
        expect(report, contains('CREATE_ACCOUNT_FAILURE'));
      },
    );
  });

  group('OAuth sign-in failure logging', () {
    test('Google failure is logged, streamed, and emits AuthError', () async {
      final mockGoogle = MockSignInWithGoogleUsecase();
      when(
        () => mockGoogle(any()),
      ).thenAnswer((_) async => const Left('OAuth login failed'));
      final cubit = AuthCubit(
        signInUsecase: MockSignInUsecase(),
        signInWithGoogleUsecase: mockGoogle,
        signInWithFacebookUsecase: MockSignInWithFacebookUsecase(),
        signUpUsecase: MockSignUpUsecase(),
        signOutUsecase: MockSignOutUsecase(),
        resetPasswordUsecase: MockResetPasswordUsecase(),
        resendConfirmationUsecase: MockResendConfirmationUsecase(),
        updatePasswordUsecase: MockUpdatePasswordUsecase(),
      watchAuthStateUsecase: MockWatchAuthStateUsecase(),
        getCurrentUserUsecase: MockGetCurrentUserUsecase(),
      );

      final streamExpectation = expectLater(
        AppLogger.instance.logStream,
        emitsThrough(
          isA<AppLogEntry>()
              .having((e) => e.level, 'level', LogLevel.error)
              .having((e) => e.category, 'category', LogCategory.authentication)
              .having((e) => e.operation, 'operation', 'signInWithGoogle'),
        ),
      );

      await cubit.signInWithGoogle();
      await streamExpectation;
      expect(cubit.state, isA<AuthError>());
      expect(
        AppLogger.instance.searchLogs('GOOGLE_SIGN_IN_OPERATION_FAILURE'),
        isNotEmpty,
      );
      await cubit.close();
    });
  });

  group('logSupabaseOperation guard', () {
    test('password resend and update flows log outcomes', () async {
      final mockResend = MockResendConfirmationUsecase();
      final mockUpdate = MockUpdatePasswordUsecase();
      when(() => mockResend(any())).thenAnswer((_) async => const Right(null));
      when(() => mockUpdate(any())).thenAnswer((_) async => const Right(null));
      final cubit = AuthCubit(
        signInUsecase: MockSignInUsecase(),
        signInWithGoogleUsecase: MockSignInWithGoogleUsecase(),
        signInWithFacebookUsecase: MockSignInWithFacebookUsecase(),
        signUpUsecase: MockSignUpUsecase(),
        signOutUsecase: MockSignOutUsecase(),
        resetPasswordUsecase: MockResetPasswordUsecase(),
        resendConfirmationUsecase: mockResend,
        updatePasswordUsecase: mockUpdate,
        watchAuthStateUsecase: MockWatchAuthStateUsecase(),
        getCurrentUserUsecase: MockGetCurrentUserUsecase(),
      );

      await cubit.resendConfirmation('a@b.com');
      expect(cubit.state, isA<AuthConfirmationResent>());
      expect(
        AppLogger.instance.searchLogs('RESEND_CONFIRMATION_SUCCESS'),
        isNotEmpty,
      );

      await cubit.updatePassword('new-secret-123');
      expect(cubit.state, isA<AuthPasswordUpdated>());
      expect(
        AppLogger.instance.searchLogs('UPDATE_PASSWORD_SUCCESS'),
        isNotEmpty,
      );
      // The password value itself must never reach the logs.
      expect(AppLogger.instance.searchLogs('new-secret-123'), isEmpty);
      await cubit.close();
    });
  });

  group('logSupabaseOperation guard', () {
    test('live auth-state stream drives session transitions once', () async {
      final mockWatch = MockWatchAuthStateUsecase();
      final controller = StreamController<UserEntity?>();
      when(
        () => mockWatch(any()),
      ).thenAnswer((_) async => Right(controller.stream));
      final cubit = AuthCubit(
        signInUsecase: MockSignInUsecase(),
        signInWithGoogleUsecase: MockSignInWithGoogleUsecase(),
        signInWithFacebookUsecase: MockSignInWithFacebookUsecase(),
        signUpUsecase: MockSignUpUsecase(),
        signOutUsecase: MockSignOutUsecase(),
        resetPasswordUsecase: MockResetPasswordUsecase(),
        resendConfirmationUsecase: MockResendConfirmationUsecase(),
        updatePasswordUsecase: MockUpdatePasswordUsecase(),
        watchAuthStateUsecase: mockWatch,
        getCurrentUserUsecase: MockGetCurrentUserUsecase(),
      );

      final emitted = <AuthState>[];
      final subscription = cubit.stream.listen(emitted.add);
      await cubit.listenToAuthState();

      const sessionUser = UserEntity(id: 'live-1', email: 'live@x.com');
      controller.add(sessionUser);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Same user again: duplicate must be skipped, no second emission.
      controller.add(sessionUser);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        emitted.whereType<AuthAuthenticated>(),
        hasLength(1),
        reason: 'same-user duplicates must not re-emit',
      );
      expect(emitted.last, isA<AuthUnauthenticated>());

      await subscription.cancel();
      await controller.close();
      await cubit.close();
    });
  });

  group('logSupabaseOperation guard', () {
    test('success returns the value and logs the trail', () async {
      final value = await logSupabaseOperation<String>(
        category: LogCategory.database,
        operation: 'guardProbeSuccess',
        action: () async => 'ok',
      );
      expect(value, 'ok');
      expect(
        AppLogger.instance.searchLogs('guardProbeSuccess succeeded'),
        isNotEmpty,
      );
    });

    test('failure logs the error with stack and rethrows', () async {
      final failure = StateError('probe failure');
      final streamExpectation = expectLater(
        AppLogger.instance.logStream,
        emitsThrough(
          isA<AppLogEntry>()
              .having((e) => e.level, 'level', LogLevel.error)
              .having((e) => e.operation, 'operation', 'guardProbeFailure'),
        ),
      );

      await expectLater(
        logSupabaseOperation<String>(
          category: LogCategory.database,
          operation: 'guardProbeFailure',
          action: () => throw failure,
        ),
        throwsA(same(failure)),
      );
      await streamExpectation;

      final persisted = AppLogger.instance.searchLogs(
        'guardProbeFailure failed',
      );
      expect(persisted, isNotEmpty);
      expect(persisted.last.errorType, 'StateError');
      expect(persisted.last.stackTrace, isNotNull);
    });
  });
}
