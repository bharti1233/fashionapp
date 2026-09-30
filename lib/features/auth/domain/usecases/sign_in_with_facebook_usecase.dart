import 'package:dartz/dartz.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/auth/domain/repositories/auth_repository.dart';

/// Facebook OAuth sign-in. Opens the provider in a browser and completes
/// via the app deep link (io.supabase.tstore://login-callback/).
/// Requires the intent-filter in AndroidManifest.xml and the provider
/// enabled in the Supabase dashboard.
class SignInWithFacebookUsecase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  SignInWithFacebookUsecase(this.repository);

  @override
  Future<Either<String, bool>> call(NoParams params) async {
    return repository.signInWithFacebook();
  }
}
