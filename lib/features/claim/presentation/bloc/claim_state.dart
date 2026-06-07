import 'package:equatable/equatable.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';

enum ClaimStatus { initial, loading, success, failure }

class ClaimState extends Equatable {
  final ClaimStatus status;
  final List<ClaimEntity> claims;
  final String? errorMessage;

  const ClaimState({
    this.status = ClaimStatus.initial,
    this.claims = const [],
    this.errorMessage,
  });

  ClaimState copyWith({
    ClaimStatus? status,
    List<ClaimEntity>? claims,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClaimState(
      status: status ?? this.status,
      claims: claims ?? this.claims,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, claims, errorMessage];
}
