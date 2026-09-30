import 'package:dartz/dartz.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/auth/domain/repositories/auth_repository.dart';

/// Live Supabase auth-state stream (sign-in/out, token refresh, session
/// expiry). Used by [AuthCubit.listenToAuthState] to keep the app's
/// authentication state synchronized without polling.
class WatchAuthStateUsecase implements UseCase<Stream<UserEntity?>, NoParams> {
  final AuthRepository repository;

  WatchAuthStateUsecase(this.repository);

  @override
  Future<Either<String, Stream<UserEntity?>>> call(NoParams params) async {
    return Right(repository.authStateChanges);
  }
}
