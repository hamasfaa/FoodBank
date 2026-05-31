import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/auth/domain/entities/google_auth_outcome.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  });

  Future<Either<Failure, GoogleAuthOutcome>> signInWithGoogle();

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> completeGoogleProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    String? photoUrl,
  });
}
