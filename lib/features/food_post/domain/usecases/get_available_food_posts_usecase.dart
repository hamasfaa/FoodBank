import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_post_entity.dart';
import '../repositories/food_post_repository.dart';

class GetAvailableFoodPostsUsecase {
  final FoodPostRepository _repository;

  const GetAvailableFoodPostsUsecase(this._repository);

  Future<Either<Failure, List<FoodPostEntity>>> call() {
    return _repository.getAvailableFoodPosts();
  }
}
