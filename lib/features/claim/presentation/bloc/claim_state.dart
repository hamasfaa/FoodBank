import 'package:equatable/equatable.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';

enum ClaimStatus { initial, loading, success, failure }

class ClaimState extends Equatable {
  final ClaimStatus status;
  final List<ClaimEntity> claims;
  final String? errorMessage;
  final String? successMessage;

  const ClaimState({
    this.status = ClaimStatus.initial,
    this.claims = const [],
    this.errorMessage,
    this.successMessage,
  });

  ClaimState copyWith({
    ClaimStatus? status,
    List<ClaimEntity>? claims,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ClaimState(
      status: status ?? this.status,
      claims: claims ?? this.claims,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, claims, errorMessage, successMessage];
}
