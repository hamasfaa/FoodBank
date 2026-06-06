import 'package:equatable/equatable.dart';
import 'food_location_entity.dart';

class FoodPostEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double quantity;
  final DateTime expiredAt;
  final String status;
  final FoodLocationEntity location;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String donorId;
  final String donorName;

  const FoodPostEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.quantity,
    required this.expiredAt,
    required this.status,
    required this.location,
    required this.imageUrls,
    required this.createdAt,
    required this.donorId,
    required this.donorName,
  });

  @override
  List<Object?> get props => [
        id, title, description, quantity, expiredAt,
        status, location, imageUrls, createdAt, donorId, donorName,
      ];
}
