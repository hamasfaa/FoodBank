import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import '../entities/food_recognition_suggestion.dart';

abstract class FoodRecognitionRepository {
  Future<Either<Failure, FoodRecognitionSuggestion>> recognizeFoodImage(
    File image,
  );
}
