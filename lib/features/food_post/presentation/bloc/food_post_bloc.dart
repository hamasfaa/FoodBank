import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/food_post/domain/usecases/create_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_my_food_posts_usecase.dart';
import 'food_post_event.dart';
import 'food_post_state.dart';

class FoodPostBloc extends Bloc<FoodPostEvent, FoodPostState> {
  final CreateFoodPostUsecase _createFoodPost;
  final GetMyFoodPostsUsecase _getMyFoodPosts;

  FoodPostBloc(this._createFoodPost, this._getMyFoodPosts)
      : super(const FoodPostState()) {
    on<CreateFoodPostSubmitted>(_onCreateFoodPostSubmitted);
    on<LoadMyFoodPosts>(_onLoadMyFoodPosts);
  }

  Future<void> _onCreateFoodPostSubmitted(
    CreateFoodPostSubmitted event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(state.copyWith(status: FoodPostStatus.loading, clearError: true));

    final result = await _createFoodPost(CreateFoodPostParams(
      donorId: event.donorId,
      donorName: event.donorName,
      title: event.title,
      description: event.description,
      quantity: event.quantity,
      expiredAt: event.expiredAt,
      location: event.location,
      images: event.images,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: FoodPostStatus.failure,
        errorMessage: failure.message,
      )),
      (post) => emit(state.copyWith(
        status: FoodPostStatus.success,
        myPosts: [post, ...state.myPosts],
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadMyFoodPosts(
    LoadMyFoodPosts event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(state.copyWith(status: FoodPostStatus.loadingPosts, clearError: true));

    final result = await _getMyFoodPosts(event.donorId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: FoodPostStatus.failure,
        errorMessage: failure.message,
      )),
      (posts) => emit(state.copyWith(
        status: FoodPostStatus.initial,
        myPosts: posts,
      )),
    );
  }
}
