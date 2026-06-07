import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/claim_entity.dart';

abstract class ClaimRepository {
  Future<Either<Failure, ClaimEntity>> createClaim({
    required String foodId,
    required String foodTitle,
    required String foodImageUrl,
    required String donorId,
    required String donorName,
    required String receiverId,
    required String receiverName,
  });

  Future<Either<Failure, List<ClaimEntity>>> getMyClaims(String receiverId);

  Future<Either<Failure, void>> cancelClaim(String claimId);
}
