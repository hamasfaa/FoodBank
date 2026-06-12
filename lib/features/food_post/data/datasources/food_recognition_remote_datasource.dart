import 'dart:io';
import 'package:foodbank/features/food_post/domain/entities/food_recognition_suggestion.dart';

abstract class FoodRecognitionRemoteDatasource {
  Future<FoodRecognitionSuggestion> recognizeFoodImage(File image);
}
