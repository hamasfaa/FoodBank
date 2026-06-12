import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_location_entity.dart';
import '../entities/food_post_entity.dart';
import '../repositories/food_post_repository.dart';

class UpdateFoodPostParams extends Equatable {
  final String postId;
  final String donorId;
  final String title;
  final String description;
  final double quantity;
  final DateTime expiredAt;
  final FoodLocationEntity location;
  final List<String> existingImageUrls;
  final List<File> newImages;

  const UpdateFoodPostParams({
    required this.postId,
    required this.donorId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.expiredAt,
    required this.location,
    required this.existingImageUrls,
    required this.newImages,
  });

  @override
  List<Object?> get props => [
    postId,
    donorId,
    title,
    description,
    quantity,
    expiredAt,
    location,
    existingImageUrls,
    newImages,
  ];
}

class UpdateFoodPostUsecase {
  final FoodPostRepository _repository;

  const UpdateFoodPostUsecase(this._repository);

  Future<Either<Failure, FoodPostEntity>> call(UpdateFoodPostParams params) {
    return _repository.updateFoodPost(
      postId: params.postId,
      donorId: params.donorId,
      title: params.title,
      description: params.description,
      quantity: params.quantity,
      expiredAt: params.expiredAt,
      location: params.location,
      existingImageUrls: params.existingImageUrls,
      newImages: params.newImages,
    );
  }
}
