import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';

class CompleteProfileUsecase {
  final AuthRepository _repository;

  const CompleteProfileUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call(CompleteProfileParams params) {
    return _repository.completeGoogleProfile(
      uid: params.uid,
      fullName: params.fullName,
      email: params.email,
      phoneNumber: params.phoneNumber,
      role: params.role,
      photoUrl: params.photoUrl,
    );
  }
}

class CompleteProfileParams extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? photoUrl;

  const CompleteProfileParams({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.photoUrl,
  });

  @override
  List<Object?> get props =>
      [uid, fullName, email, phoneNumber, role, photoUrl];
}
