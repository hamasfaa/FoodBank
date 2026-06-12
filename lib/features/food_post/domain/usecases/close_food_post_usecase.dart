import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_post_entity.dart';
import '../repositories/food_post_repository.dart';

class CloseFoodPostParams extends Equatable {
  final String postId;
  final String donorId;

  const CloseFoodPostParams({required this.postId, required this.donorId});

  @override
  List<Object?> get props => [postId, donorId];
}

class CloseFoodPostUsecase {
  final FoodPostRepository _repository;

  const CloseFoodPostUsecase(this._repository);

  Future<Either<Failure, FoodPostEntity>> call(CloseFoodPostParams params) {
    return _repository.closeFoodPost(
      postId: params.postId,
      donorId: params.donorId,
    );
  }
}
