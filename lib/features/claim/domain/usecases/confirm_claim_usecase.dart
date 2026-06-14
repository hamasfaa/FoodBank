import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../repositories/claim_repository.dart';

class ConfirmClaimParams extends Equatable {
  final String claimId;
  final String donorId;

  const ConfirmClaimParams({required this.claimId, required this.donorId});

  @override
  List<Object?> get props => [claimId, donorId];
}

class ConfirmClaimUsecase {
  final ClaimRepository _repository;

  const ConfirmClaimUsecase(this._repository);

  Future<Either<Failure, void>> call(ConfirmClaimParams params) {
    return _repository.confirmClaim(
      claimId: params.claimId,
      donorId: params.donorId,
    );
  }
}
