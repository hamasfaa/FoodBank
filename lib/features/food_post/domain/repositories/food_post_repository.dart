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

  Future<Either<Failure, List<FoodPostEntity>>> getMyFoodPosts(String donorId);
}
