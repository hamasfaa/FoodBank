import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/claim/domain/usecases/cancel_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/confirm_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/create_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/get_incoming_claims_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/get_my_claims_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/reject_claim_usecase.dart';
import 'claim_event.dart';
import 'claim_state.dart';

class ClaimBloc extends Bloc<ClaimEvent, ClaimState> {
  final CreateClaimUsecase _createClaim;
  final GetMyClaimsUsecase _getMyClaims;
  final CancelClaimUsecase _cancelClaim;
  final GetIncomingClaimsUsecase _getIncomingClaims;
  final ConfirmClaimUsecase _confirmClaim;
  final RejectClaimUsecase _rejectClaim;

  ClaimBloc(
    this._createClaim,
    this._getMyClaims,
    this._cancelClaim,
    this._getIncomingClaims,
    this._confirmClaim,
    this._rejectClaim,
  ) : super(const ClaimState()) {
    on<LoadMyClaims>(_onLoadMyClaims);
    on<LoadIncomingClaims>(_onLoadIncomingClaims);
    on<CreateClaim>(_onCreateClaim);
    on<CancelClaim>(_onCancelClaim);
    on<ConfirmClaim>(_onConfirmClaim);
    on<RejectClaim>(_onRejectClaim);
  }

  Future<void> _onLoadMyClaims(
    LoadMyClaims event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _getMyClaims(event.receiverId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (claims) => emit(
        state.copyWith(
          status: ClaimStatus.initial,
          claims: claims,
          clearSuccess: true,
        ),
      ),
    );
  }

  Future<void> _onLoadIncomingClaims(
    LoadIncomingClaims event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _getIncomingClaims(event.donorId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (claims) => emit(
        state.copyWith(
          status: ClaimStatus.initial,
          claims: claims,
          clearSuccess: true,
        ),
      ),
    );
  }

  Future<void> _onCreateClaim(
    CreateClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _createClaim(
      CreateClaimParams(
        foodId: event.foodId,
        foodTitle: event.foodTitle,
        foodImageUrl: event.foodImageUrl,
        donorId: event.donorId,
        donorName: event.donorName,
        receiverId: event.receiverId,
        receiverName: event.receiverName,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (claim) => emit(
        state.copyWith(
          status: ClaimStatus.success,
          claims: [claim, ...state.claims],
          successMessage: 'Klaim berhasil dibuat',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onCancelClaim(
    CancelClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _cancelClaim(event.claimId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) {
        final updated = state.claims.map((c) {
          if (c.id == event.claimId) {
            return c.copyWith(status: 'cancelled');
          }
          return c;
        }).toList();

        emit(
          state.copyWith(
            status: ClaimStatus.success,
            claims: updated,
            successMessage: 'Klaim berhasil dibatalkan',
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onConfirmClaim(
    ConfirmClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _confirmClaim(
      ConfirmClaimParams(claimId: event.claimId, donorId: event.donorId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) {
        final confirmedAt = DateTime.now();
        final updated = state.claims.map((claim) {
          if (claim.id == event.claimId) {
            return claim.copyWith(
              status: 'confirmed',
              confirmedAt: confirmedAt,
            );
          }
          if (claim.foodId == event.foodId && claim.status == 'pending') {
            return claim.copyWith(status: 'cancelled');
          }
          return claim;
        }).toList();

        emit(
          state.copyWith(
            status: ClaimStatus.success,
            claims: updated,
            successMessage: 'Klaim berhasil dikonfirmasi',
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onRejectClaim(
    RejectClaim event,
    Emitter<ClaimState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClaimStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _rejectClaim(
      RejectClaimParams(claimId: event.claimId, donorId: event.donorId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClaimStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) {
        final updated = state.claims.map((claim) {
          if (claim.id == event.claimId) {
            return claim.copyWith(status: 'cancelled');
          }
          return claim;
        }).toList();

        emit(
          state.copyWith(
            status: ClaimStatus.success,
            claims: updated,
            successMessage: 'Klaim berhasil ditolak',
            clearError: true,
          ),
        );
      },
    );
  }
}
