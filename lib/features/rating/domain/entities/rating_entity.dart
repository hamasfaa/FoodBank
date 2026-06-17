import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String claimId;
  final String donorId;
  final String receiverId;
  final int score;
  final String comment;
  final String photoUrl;
  final bool isVerifiedByAdmin;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.claimId,
    required this.donorId,
    required this.receiverId,
    required this.score,
    required this.comment,
    required this.photoUrl,
    required this.isVerifiedByAdmin,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        claimId,
        donorId,
        receiverId,
        score,
        comment,
        photoUrl,
        isVerifiedByAdmin,
        createdAt,
      ];
}
