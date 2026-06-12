import 'package:equatable/equatable.dart';

class FoodRecognitionCandidate extends Equatable {
  final String name;
  final double? confidence;

  const FoodRecognitionCandidate({required this.name, this.confidence});

  @override
  List<Object?> get props => [name, confidence];
}

class FoodRecognitionSuggestion extends Equatable {
  final int? imageId;
  final List<FoodRecognitionCandidate> candidates;
  final List<String> foodGroups;
  final List<String> foodTypes;
  final String? suggestedTitle;
  final String? suggestedDescription;
  final String? category;
  final String? estimatedCalories;
  final List<String> ingredients;

  const FoodRecognitionSuggestion({
    required this.candidates,
    this.imageId,
    this.foodGroups = const [],
    this.foodTypes = const [],
    this.suggestedTitle,
    this.suggestedDescription,
    this.category,
    this.estimatedCalories,
    this.ingredients = const [],
  });

  FoodRecognitionCandidate get bestCandidate => candidates.first;

  @override
  List<Object?> get props => [
    imageId,
    candidates,
    foodGroups,
    foodTypes,
    suggestedTitle,
    suggestedDescription,
    category,
    estimatedCalories,
    ingredients,
  ];
}
