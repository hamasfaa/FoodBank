import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/auth/domain/entities/google_auth_outcome.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignInUsecase {
  final AuthRepository _repository;

  const GoogleSignInUsecase(this._repository);

  Future<Either<Failure, GoogleAuthOutcome>> call() {
    return _repository.signInWithGoogle();
  }
}
