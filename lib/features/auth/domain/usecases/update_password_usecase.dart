import 'package:dartz/dartz.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/auth/domain/repositories/auth_repository.dart';

/// Updates the password of the currently authenticated (or recovery
/// session) user. Used by the reset-password screen. The new password
/// is never logged — only the operation outcome.
class UpdatePasswordUsecase implements UseCase<void, String> {
  final AuthRepository repository;

  UpdatePasswordUsecase(this.repository);

  @override
  Future<Either<String, void>> call(String newPassword) async {
    return repository.updatePassword(newPassword);
  }
}
