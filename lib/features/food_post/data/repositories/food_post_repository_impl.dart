import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/food_post/domain/entities/food_location_entity.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/features/food_post/domain/repositories/food_post_repository.dart';
import '../datasources/food_post_remote_datasource.dart';

class FoodPostRepositoryImpl implements FoodPostRepository {
  final FoodPostRemoteDatasource _datasource;

  const FoodPostRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, FoodPostEntity>> createFoodPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<File> images,
  }) async {
    try {
      final post = await _datasource.createFoodPost(
        donorId: donorId,
        donorName: donorName,
        title: title,
        description: description,
        quantity: quantity,
        expiredAt: expiredAt,
        location: location,
        images: images,
      );
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
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
  }) async {
    try {
      final post = await _datasource.updateFoodPost(
        postId: postId,
        donorId: donorId,
        title: title,
        description: description,
        quantity: quantity,
        expiredAt: expiredAt,
        location: location,
        existingImageUrls: existingImageUrls,
        newImages: newImages,
      );
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, FoodPostEntity>> closeFoodPost({
    required String postId,
    required String donorId,
  }) async {
    try {
      final post = await _datasource.closeFoodPost(
        postId: postId,
        donorId: donorId,
      );
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFoodPost({
    required String postId,
    required String donorId,
  }) async {
    try {
      await _datasource.deleteFoodPost(postId: postId, donorId: donorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, List<FoodPostEntity>>> getMyFoodPosts(
    String donorId,
  ) async {
    try {
      final posts = await _datasource.getMyFoodPosts(donorId);
      return Right(posts);
    } catch (e) {
      return const Left(ServerFailure('Gagal memuat postingan, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, List<FoodPostEntity>>> getAvailableFoodPosts() async {
    try {
      final posts = await _datasource.getAvailableFoodPosts();
      return Right(posts);
    } catch (e) {
      return const Left(
        ServerFailure('Gagal memuat makanan tersedia, coba lagi'),
      );
    }
  }
}
