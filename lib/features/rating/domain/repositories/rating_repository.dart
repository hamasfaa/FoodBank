import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, RatingEntity>> createRating({
    required String claimId,
    required String donorId,
    required String receiverId,
    required int score,
    required String comment,
  });
}
