import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_location_entity.dart';
import '../entities/food_post_entity.dart';
import '../repositories/food_post_repository.dart';

class CreateFoodPostParams extends Equatable {
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final double quantity;
  final DateTime expiredAt;
  final FoodLocationEntity location;
  final List<File> images;

  const CreateFoodPostParams({
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    required this.quantity,
    required this.expiredAt,
    required this.location,
    required this.images,
  });

  @override
  List<Object?> get props => [
        donorId, donorName, title, description,
        quantity, expiredAt, location, images,
      ];
}

class CreateFoodPostUsecase {
  final FoodPostRepository _repository;

  const CreateFoodPostUsecase(this._repository);

  Future<Either<Failure, FoodPostEntity>> call(CreateFoodPostParams params) {
    return _repository.createFoodPost(
      donorId: params.donorId,
      donorName: params.donorName,
      title: params.title,
      description: params.description,
      quantity: params.quantity,
      expiredAt: params.expiredAt,
      location: params.location,
      images: params.images,
    );
  }
}
