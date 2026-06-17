import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class CreateRatingParams {
  final String claimId;
  final String donorId;
  final String receiverId;
  final int score;
  final String comment;

  const CreateRatingParams({
    required this.claimId,
    required this.donorId,
    required this.receiverId,
    required this.score,
    required this.comment,
  });
}

class CreateRatingUsecase {
  final RatingRepository _repository;

  const CreateRatingUsecase(this._repository);

  Future<Either<Failure, RatingEntity>> call(CreateRatingParams params) {
    return _repository.createRating(
      claimId: params.claimId,
      donorId: params.donorId,
      receiverId: params.receiverId,
      score: params.score,
      comment: params.comment,
    );
  }
}
