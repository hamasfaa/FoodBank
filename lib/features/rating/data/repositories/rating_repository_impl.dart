import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/rating/domain/entities/rating_entity.dart';
import 'package:foodbank/features/rating/domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDatasource _datasource;

  const RatingRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, RatingEntity>> createRating({
    required String claimId,
    required String donorId,
    required String receiverId,
    required int score,
    required String comment,
    required String photoUrl,
  }) async {
    try {
      final rating = await _datasource.createRating(
        claimId: claimId,
        donorId: donorId,
        receiverId: receiverId,
        score: score,
        comment: comment,
        photoUrl: photoUrl,
      );
      return Right(rating);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
