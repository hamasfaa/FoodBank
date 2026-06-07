import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:foodbank/features/food_post/domain/entities/food_location_entity.dart';

abstract class FoodPostEvent extends Equatable {
  const FoodPostEvent();

  @override
  List<Object?> get props => [];
}

class CreateFoodPostSubmitted extends FoodPostEvent {
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final double quantity;
  final DateTime expiredAt;
  final FoodLocationEntity location;
  final List<File> images;

  const CreateFoodPostSubmitted({
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

class LoadMyFoodPosts extends FoodPostEvent {
  final String donorId;

  const LoadMyFoodPosts(this.donorId);

  @override
  List<Object?> get props => [donorId];
}

class LoadAvailableFoodPosts extends FoodPostEvent {
  const LoadAvailableFoodPosts();
}
