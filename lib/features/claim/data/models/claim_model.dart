import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';

class ClaimModel extends ClaimEntity {
  const ClaimModel({
    required super.id,
    required super.foodId,
    required super.foodTitle,
    required super.foodImageUrl,
    required super.donorId,
    required super.donorName,
    required super.receiverId,
    required super.receiverName,
    required super.status,
    required super.claimedAt,
    super.confirmedAt,
    super.isVerifiedByAdmin,
  });

  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimModel(
      id: doc.id,
      foodId: data['foodId'] as String,
      foodTitle: data['foodTitle'] as String,
      foodImageUrl: data['foodImageUrl'] as String? ?? '',
      donorId: data['donorId'] as String,
      donorName: data['donorName'] as String,
      receiverId: data['receiverId'] as String,
      receiverName: data['receiverName'] as String,
      status: data['status'] as String,
      claimedAt: (data['claimedAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      isVerifiedByAdmin: data['isVerifiedByAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'foodId': foodId,
        'foodTitle': foodTitle,
        'foodImageUrl': foodImageUrl,
        'donorId': donorId,
        'donorName': donorName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'status': status,
        'claimedAt': Timestamp.fromDate(claimedAt),
        'confirmedAt':
            confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
        'isVerifiedByAdmin': isVerifiedByAdmin,
      };
}
