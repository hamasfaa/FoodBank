import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../repositories/claim_repository.dart';

class RejectClaimParams extends Equatable {
  final String claimId;
  final String donorId;

  const RejectClaimParams({required this.claimId, required this.donorId});

  @override
  List<Object?> get props => [claimId, donorId];
}

class RejectClaimUsecase {
  final ClaimRepository _repository;

  const RejectClaimUsecase(this._repository);

  Future<Either<Failure, void>> call(RejectClaimParams params) {
    return _repository.rejectClaim(
      claimId: params.claimId,
      donorId: params.donorId,
    );
  }
}
