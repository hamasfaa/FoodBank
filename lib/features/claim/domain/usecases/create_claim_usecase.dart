import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/claim_entity.dart';
import '../repositories/claim_repository.dart';

class CreateClaimParams {
  final String foodId;
  final String foodTitle;
  final String foodImageUrl;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;

  const CreateClaimParams({
    required this.foodId,
    required this.foodTitle,
    required this.foodImageUrl,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
  });
}

class CreateClaimUsecase {
  final ClaimRepository _repository;

  const CreateClaimUsecase(this._repository);

  Future<Either<Failure, ClaimEntity>> call(CreateClaimParams params) {
    return _repository.createClaim(
      foodId: params.foodId,
      foodTitle: params.foodTitle,
      foodImageUrl: params.foodImageUrl,
      donorId: params.donorId,
      donorName: params.donorName,
      receiverId: params.receiverId,
      receiverName: params.receiverName,
    );
  }
}
