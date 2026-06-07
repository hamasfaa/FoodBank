import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbank/features/rating/domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.id,
    required super.claimId,
    required super.donorId,
    required super.receiverId,
    required super.score,
    required super.comment,
    required super.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      claimId: data['claimId'] as String,
      donorId: data['donorId'] as String,
      receiverId: data['receiverId'] as String,
      score: data['score'] as int,
      comment: data['comment'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'claimId': claimId,
        'donorId': donorId,
        'receiverId': receiverId,
        'score': score,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
