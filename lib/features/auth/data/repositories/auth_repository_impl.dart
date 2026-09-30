import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/supabase/supabase_tables.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/data/models/user_model.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService supabaseService;

  AuthRepositoryImpl({required this.supabaseService});

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = supabaseService.currentUser;
      if (user == null) {
        return const Right(null);
      }

      // Get profile data
      final profileData = await supabaseService.client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        return Right(UserModel.fromJson(profileData));
      }

      // Return basic user info if no profile exists
      return Right(
        UserEntity(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Get current user failed',
        category: LogCategory.authentication,
        event: 'GET_CURRENT_USER_FAILURE',
        screen: 'AuthRepository',
        operation: 'getCurrentUser',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        AppLogger.instance.error(
          message: 'Sign-in failed: Supabase returned no user',
          category: LogCategory.authentication,
          event: 'SIGN_IN_FAILURE',
          screen: 'AuthRepository',
          operation: 'signIn',
        );
        return const Left('Login failed');
      }

      // Get profile
      final profileData = await supabaseService.client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profileData != null) {
        return Right(UserModel.fromJson(profileData));
      }

      return Right(
        UserEntity(id: response.user!.id, email: response.user!.email ?? email),
      );
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Sign-in failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signIn',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Sign-in failed with unexpected error',
        category: LogCategory.authentication,
        event: 'SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signIn',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? emailRedirectTo,
  }) async {
    try {
      final response = await supabaseService.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailRedirectTo,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (response.user == null) {
        AppLogger.instance.error(
          message: 'Sign-up failed: Supabase returned no user',
          category: LogCategory.authentication,
          event: 'SIGN_UP_FAILURE',
          screen: 'AuthRepository',
          operation: 'signUp',
        );
        return const Left('Account creation failed');
      }

      return Right(
        UserEntity(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          phone: phone,
        ),
      );
    } on AuthException catch (e, stackTrace) {
      // Log the TECHNICAL error; the UI receives a friendly message.
      AppLogger.instance.error(
        message: 'Sign-up failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'SIGN_UP_FAILURE',
        screen: 'AuthRepository',
        operation: 'signUp',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Sign-up failed with unexpected error',
        category: LogCategory.authentication,
        event: 'SIGN_UP_FAILURE',
        screen: 'AuthRepository',
        operation: 'signUp',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> signInWithGoogle() async {
    try {
      final success = await supabaseService.signInWithGoogle();
      return Right(success);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Google sign-in failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'GOOGLE_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithGoogle',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Google sign-in failed with unexpected error',
        category: LogCategory.authentication,
        event: 'GOOGLE_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithGoogle',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> signInWithFacebook() async {
    try {
      final success = await supabaseService.signInWithFacebook();
      return Right(success);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Facebook sign-in failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'FACEBOOK_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithFacebook',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Facebook sign-in failed with unexpected error',
        category: LogCategory.authentication,
        event: 'FACEBOOK_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithFacebook',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> signInWithApple() async {
    try {
      final success = await supabaseService.signInWithApple();
      return Right(success);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Apple sign-in failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'APPLE_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithApple',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Apple sign-in failed with unexpected error',
        category: LogCategory.authentication,
        event: 'APPLE_SIGN_IN_FAILURE',
        screen: 'AuthRepository',
        operation: 'signInWithApple',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await supabaseService.signOut();
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Sign-out failed',
        category: LogCategory.authentication,
        event: 'SIGN_OUT_FAILURE',
        screen: 'AuthRepository',
        operation: 'signOut',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> resetPassword(String email) async {
    try {
      await supabaseService.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Password reset failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'RESET_PASSWORD_FAILURE',
        screen: 'AuthRepository',
        operation: 'resetPassword',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Password reset failed with unexpected error',
        category: LogCategory.authentication,
        event: 'RESET_PASSWORD_FAILURE',
        screen: 'AuthRepository',
        operation: 'resetPassword',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updatePassword(String newPassword) async {
    try {
      await supabaseService.updatePassword(newPassword);
      return const Right(null);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Password update failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'UPDATE_PASSWORD_FAILURE',
        screen: 'AuthRepository',
        operation: 'updatePassword',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Password update failed with unexpected error',
        category: LogCategory.authentication,
        event: 'UPDATE_PASSWORD_FAILURE',
        screen: 'AuthRepository',
        operation: 'updatePassword',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> resendConfirmation(String email) async {
    try {
      await supabaseService.resendConfirmation(email);
      return const Right(null);
    } on AuthException catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Resend confirmation failed: ${e.message}',
        category: LogCategory.authentication,
        event: 'RESEND_CONFIRMATION_FAILURE',
        screen: 'AuthRepository',
        operation: 'resendConfirmation',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_getAuthErrorMessage(e.message));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Resend confirmation failed with unexpected error',
        category: LogCategory.authentication,
        event: 'RESEND_CONFIRMATION_FAILURE',
        screen: 'AuthRepository',
        operation: 'resendConfirmation',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  bool get isLoggedIn => supabaseService.isLoggedIn;

  @override
  Stream<UserEntity?> get authStateChanges {
    return supabaseService.authStateChanges.asyncMap((state) async {
      if (state.session?.user == null) {
        return null;
      }

      final user = state.session!.user;

      // Get profile
      final profileData = await supabaseService.client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        return UserModel.fromJson(profileData);
      }

      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String?,
      );
    });
  }

  String _getAuthErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'Please confirm your email first';
    }
    if (lowerMessage.contains('user already registered')) {
      return 'This email is already registered';
    }
    if (lowerMessage.contains('password')) {
      return 'Password must be at least 6 characters';
    }
    if (lowerMessage.contains('email')) {
      return 'Please enter a valid email address';
    }
    if (lowerMessage.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    }
    if (lowerMessage.contains('provider is not enabled') ||
        lowerMessage.contains('unsupported provider') ||
        lowerMessage.contains('validation_failed')) {
      // Server-side provider configuration issue: honest, actionable,
      // and never a fake success. The technical detail is logged.
      return 'This sign-in method is not available yet. '
          'Please use email sign-in.';
    }

    return message;
  }
}
