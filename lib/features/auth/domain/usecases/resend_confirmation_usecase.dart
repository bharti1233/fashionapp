import 'package:dartz/dartz.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/auth/domain/repositories/auth_repository.dart';

/// Resends the signup confirmation email. Used by the verify-email
/// screen when the user did not receive (or lost) the first email.
class ResendConfirmationUsecase implements UseCase<void, String> {
  final AuthRepository repository;

  ResendConfirmationUsecase(this.repository);

  @override
  Future<Either<String, void>> call(String email) async {
    return repository.resendConfirmation(email);
  }
}
