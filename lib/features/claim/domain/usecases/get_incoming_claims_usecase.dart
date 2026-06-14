import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import '../repositories/claim_repository.dart';

class GetIncomingClaimsUsecase {
  final ClaimRepository _repository;

  const GetIncomingClaimsUsecase(this._repository);

  Future<Either<Failure, List<ClaimEntity>>> call(String donorId) {
    return _repository.getIncomingClaims(donorId);
  }
}
