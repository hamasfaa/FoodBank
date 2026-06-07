import 'package:equatable/equatable.dart';

class ClaimEntity extends Equatable {
  final String id;
  final String foodId;
  final String foodTitle;
  final String foodImageUrl;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final String status; // pending, confirmed, cancelled, verified
  final DateTime claimedAt;
  final DateTime? confirmedAt;
  final bool isVerifiedByAdmin;

  const ClaimEntity({
    required this.id,
    required this.foodId,
    required this.foodTitle,
    required this.foodImageUrl,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.claimedAt,
    this.confirmedAt,
    this.isVerifiedByAdmin = false,
  });

  @override
  List<Object?> get props => [
        id, foodId, foodTitle, foodImageUrl,
        donorId, donorName, receiverId, receiverName,
        status, claimedAt, confirmedAt, isVerifiedByAdmin,
      ];
}
