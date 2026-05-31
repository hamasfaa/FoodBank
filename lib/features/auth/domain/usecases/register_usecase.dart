import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository _repository;

  const RegisterUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return _repository.register(
      fullName: params.fullName,
      email: params.email,
      phoneNumber: params.phoneNumber,
      password: params.password,
      role: params.role,
    );
  }
}

class RegisterParams extends Equatable {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String role;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, email, phoneNumber, password, role];
}
