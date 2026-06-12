import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/food_post/data/datasources/gemini_food_recognition_remote_datasource.dart';
import 'package:foodbank/features/food_post/domain/entities/food_recognition_suggestion.dart';
import 'package:foodbank/features/food_post/domain/repositories/food_recognition_repository.dart';
import '../datasources/food_recognition_remote_datasource.dart';

class FoodRecognitionRepositoryImpl implements FoodRecognitionRepository {
  final FoodRecognitionRemoteDatasource _datasource;

  const FoodRecognitionRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, FoodRecognitionSuggestion>> recognizeFoodImage(
    File image,
  ) async {
    try {
      final suggestion = await _datasource.recognizeFoodImage(image);
      return Right(suggestion);
    } on GeminiFoodRecognitionException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(NetworkFailure('Gagal menghubungi AI, coba lagi'));
    }
  }
}
