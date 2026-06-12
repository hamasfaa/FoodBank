import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../repositories/food_post_repository.dart';

class DeleteFoodPostParams extends Equatable {
  final String postId;
  final String donorId;

  const DeleteFoodPostParams({required this.postId, required this.donorId});

  @override
  List<Object?> get props => [postId, donorId];
}

class DeleteFoodPostUsecase {
  final FoodPostRepository _repository;

  const DeleteFoodPostUsecase(this._repository);

  Future<Either<Failure, void>> call(DeleteFoodPostParams params) {
    return _repository.deleteFoodPost(
      postId: params.postId,
      donorId: params.donorId,
    );
  }
}
