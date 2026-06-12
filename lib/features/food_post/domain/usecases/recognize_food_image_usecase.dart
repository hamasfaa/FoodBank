import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_recognition_suggestion.dart';
import '../repositories/food_recognition_repository.dart';

class RecognizeFoodImageUsecase {
  final FoodRecognitionRepository _repository;

  const RecognizeFoodImageUsecase(this._repository);

  Future<Either<Failure, FoodRecognitionSuggestion>> call(File image) {
    return _repository.recognizeFoodImage(image);
  }
}
