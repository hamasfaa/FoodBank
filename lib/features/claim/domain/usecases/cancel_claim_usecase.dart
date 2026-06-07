import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../repositories/claim_repository.dart';

class CancelClaimUsecase {
  final ClaimRepository _repository;

  const CancelClaimUsecase(this._repository);

  Future<Either<Failure, void>> call(String claimId) {
    return _repository.cancelClaim(claimId);
  }
}
