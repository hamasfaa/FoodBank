import 'package:equatable/equatable.dart';

enum RatingStatus { initial, loading, success, failure }

class RatingState extends Equatable {
  final RatingStatus status;
  final String? errorMessage;

  const RatingState({
    this.status = RatingStatus.initial,
    this.errorMessage,
  });

  RatingState copyWith({
    RatingStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RatingState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
