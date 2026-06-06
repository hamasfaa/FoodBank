import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_post_entity.dart';
import '../repositories/food_post_repository.dart';

class GetMyFoodPostsUsecase {
  final FoodPostRepository _repository;

  const GetMyFoodPostsUsecase(this._repository);

  Future<Either<Failure, List<FoodPostEntity>>> call(String donorId) {
    return _repository.getMyFoodPosts(donorId);
  }
}
