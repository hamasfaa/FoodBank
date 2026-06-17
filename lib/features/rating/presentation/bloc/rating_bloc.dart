import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/rating/domain/usecases/create_rating_usecase.dart';
import 'rating_event.dart';
import 'rating_state.dart';

class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final CreateRatingUsecase _createRating;

  RatingBloc(this._createRating) : super(const RatingState()) {
    on<SubmitRating>(_onSubmitRating);
  }

  Future<void> _onSubmitRating(
    SubmitRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(state.copyWith(status: RatingStatus.loading, clearError: true));

    final result = await _createRating(CreateRatingParams(
      claimId: event.claimId,
      donorId: event.donorId,
      receiverId: event.receiverId,
      score: event.score,
      comment: event.comment,
      photoUrl: event.photoUrl,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: RatingStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: RatingStatus.success,
        clearError: true,
      )),
    );
  }
}
