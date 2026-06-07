import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import 'package:foodbank/features/claim/domain/usecases/cancel_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/create_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/get_my_claims_usecase.dart';
import 'claim_event.dart';
import 'claim_state.dart';

class ClaimBloc extends Bloc<ClaimEvent, ClaimState> {
  final CreateClaimUsecase _createClaim;
  final GetMyClaimsUsecase _getMyClaims;
  final CancelClaimUsecase _cancelClaim;

  ClaimBloc(this._createClaim, this._getMyClaims, this._cancelClaim)
      : super(const ClaimState()) {
    on<LoadMyClaims>(_onLoadMyClaims);
    on<CreateClaim>(_onCreateClaim);
    on<CancelClaim>(_onCancelClaim);
  }

  Future<void> _onLoadMyClaims(
    LoadMyClaims event,
    Emitter<ClaimState> emit,
  ) async {
    emit(state.copyWith(status: ClaimStatus.loading, clearError: true));

    final result = await _getMyClaims(event.receiverId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ClaimStatus.failure,
        errorMessage: failure.message,
      )),
      (claims) => emit(state.copyWith(
        status: ClaimStatus.initial,
        claims: claims,
      )),
    );
  }

  Future<void> _onCreateClaim(
    CreateClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(state.copyWith(status: ClaimStatus.loading, clearError: true));

    final result = await _createClaim(CreateClaimParams(
      foodId: event.foodId,
      foodTitle: event.foodTitle,
      foodImageUrl: event.foodImageUrl,
      donorId: event.donorId,
      donorName: event.donorName,
      receiverId: event.receiverId,
      receiverName: event.receiverName,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ClaimStatus.failure,
        errorMessage: failure.message,
      )),
      (claim) => emit(state.copyWith(
        status: ClaimStatus.success,
        claims: [claim, ...state.claims],
        clearError: true,
      )),
    );
  }

  Future<void> _onCancelClaim(
    CancelClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(state.copyWith(status: ClaimStatus.loading, clearError: true));

    final result = await _cancelClaim(event.claimId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ClaimStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updated = state.claims.map((c) {
          if (c.id == event.claimId) {
            return ClaimEntity(
              id: c.id,
              foodId: c.foodId,
              foodTitle: c.foodTitle,
              foodImageUrl: c.foodImageUrl,
              donorId: c.donorId,
              donorName: c.donorName,
              receiverId: c.receiverId,
              receiverName: c.receiverName,
              status: 'cancelled',
              claimedAt: c.claimedAt,
              confirmedAt: c.confirmedAt,
              isVerifiedByAdmin: c.isVerifiedByAdmin,
            );
          }
          return c;
        }).toList();

        emit(state.copyWith(
          status: ClaimStatus.success,
          claims: updated,
          clearError: true,
        ));
      },
    );
  }
}
