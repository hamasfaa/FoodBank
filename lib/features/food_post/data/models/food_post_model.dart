import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbank/features/food_post/domain/entities/food_location_entity.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';

class FoodPostModel extends FoodPostEntity {
  const FoodPostModel({
    required super.id,
    required super.title,
    required super.description,
    required super.quantity,
    required super.expiredAt,
    required super.status,
    required super.location,
    required super.imageUrls,
    required super.createdAt,
    required super.donorId,
    required super.donorName,
  });

  factory FoodPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final loc = data['location'] as Map<String, dynamic>;
    return FoodPostModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      expiredAt: (data['expiredAt'] as Timestamp).toDate(),
      status: data['status'] as String,
      location: FoodLocationEntity(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
        address: loc['address'] as String,
      ),
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      donorId: data['donorId'] as String,
      donorName: data['donorName'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'description': description,
        'quantity': quantity,
        'expiredAt': Timestamp.fromDate(expiredAt),
        'status': status,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': location.address,
        },
        'imageUrls': imageUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'donorId': donorId,
        'donorName': donorName,
      };
}
