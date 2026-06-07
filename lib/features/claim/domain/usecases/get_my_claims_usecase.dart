import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/claim_entity.dart';
import '../repositories/claim_repository.dart';

class GetMyClaimsUsecase {
  final ClaimRepository _repository;

  const GetMyClaimsUsecase(this._repository);

  Future<Either<Failure, List<ClaimEntity>>> call(String receiverId) {
    return _repository.getMyClaims(receiverId);
  }
}
