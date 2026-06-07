import 'package:equatable/equatable.dart';

abstract class ClaimEvent extends Equatable {
  const ClaimEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyClaims extends ClaimEvent {
  final String receiverId;
  const LoadMyClaims(this.receiverId);

  @override
  List<Object?> get props => [receiverId];
}

class CreateClaim extends ClaimEvent {
  final String foodId;
  final String foodTitle;
  final String foodImageUrl;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;

  const CreateClaim({
    required this.foodId,
    required this.foodTitle,
    required this.foodImageUrl,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  List<Object?> get props => [foodId, receiverId];
}

class CancelClaim extends ClaimEvent {
  final String claimId;
  const CancelClaim(this.claimId);

  @override
  List<Object?> get props => [claimId];
}
