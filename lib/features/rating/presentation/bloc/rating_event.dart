import 'package:equatable/equatable.dart';

abstract class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

class SubmitRating extends RatingEvent {
  final String claimId;
  final String donorId;
  final String receiverId;
  final int score;
  final String comment;
  final String photoUrl;

  const SubmitRating({
    required this.claimId,
    required this.donorId,
    required this.receiverId,
    required this.score,
    required this.comment,
    required this.photoUrl,
  });

  @override
  List<Object?> get props => [claimId, score, comment, photoUrl];
}
