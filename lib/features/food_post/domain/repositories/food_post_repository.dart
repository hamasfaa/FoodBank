import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_location_entity.dart';
import '../entities/food_post_entity.dart';

abstract class FoodPostRepository {
  Future<Either<Failure, FoodPostEntity>> createFoodPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<File> images,
  });

  Future<Either<Failure, FoodPostEntity>> updateFoodPost({
    required String postId,
    required String donorId,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<String> existingImageUrls,
    required List<File> newImages,
  });

  Future<Either<Failure, FoodPostEntity>> closeFoodPost({
    required String postId,
    required String donorId,
  });

  Future<Either<Failure, void>> deleteFoodPost({
    required String postId,
    required String donorId,
  });

  Future<Either<Failure, List<FoodPostEntity>>> getMyFoodPosts(String donorId);

  Future<Either<Failure, List<FoodPostEntity>>> getAvailableFoodPosts();
}
