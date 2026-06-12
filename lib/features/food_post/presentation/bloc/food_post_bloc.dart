import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/features/food_post/domain/usecases/close_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/create_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/delete_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_available_food_posts_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_my_food_posts_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/update_food_post_usecase.dart';
import 'food_post_event.dart';
import 'food_post_state.dart';

class FoodPostBloc extends Bloc<FoodPostEvent, FoodPostState> {
  final CreateFoodPostUsecase _createFoodPost;
  final GetMyFoodPostsUsecase _getMyFoodPosts;
  final GetAvailableFoodPostsUsecase _getAvailableFoodPosts;
  final UpdateFoodPostUsecase _updateFoodPost;
  final CloseFoodPostUsecase _closeFoodPost;
  final DeleteFoodPostUsecase _deleteFoodPost;

  FoodPostBloc(
    this._createFoodPost,
    this._getMyFoodPosts,
    this._getAvailableFoodPosts,
    this._updateFoodPost,
    this._closeFoodPost,
    this._deleteFoodPost,
  ) : super(const FoodPostState()) {
    on<CreateFoodPostSubmitted>(_onCreateFoodPostSubmitted);
    on<UpdateFoodPostSubmitted>(_onUpdateFoodPostSubmitted);
    on<CloseFoodPostRequested>(_onCloseFoodPostRequested);
    on<DeleteFoodPostRequested>(_onDeleteFoodPostRequested);
    on<LoadMyFoodPosts>(_onLoadMyFoodPosts);
    on<LoadAvailableFoodPosts>(_onLoadAvailableFoodPosts);
  }

  Future<void> _onCreateFoodPostSubmitted(
    CreateFoodPostSubmitted event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodPostStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _createFoodPost(
      CreateFoodPostParams(
        donorId: event.donorId,
        donorName: event.donorName,
        title: event.title,
        description: event.description,
        quantity: event.quantity,
        expiredAt: event.expiredAt,
        location: event.location,
        images: event.images,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (post) => emit(
        state.copyWith(
          status: FoodPostStatus.success,
          myPosts: [post, ...state.myPosts],
          successMessage: 'Postingan berhasil dibuat!',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onUpdateFoodPostSubmitted(
    UpdateFoodPostSubmitted event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodPostStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _updateFoodPost(
      UpdateFoodPostParams(
        postId: event.postId,
        donorId: event.donorId,
        title: event.title,
        description: event.description,
        quantity: event.quantity,
        expiredAt: event.expiredAt,
        location: event.location,
        existingImageUrls: event.existingImageUrls,
        newImages: event.newImages,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (post) => emit(
        state.copyWith(
          status: FoodPostStatus.success,
          myPosts: _replacePost(state.myPosts, post),
          availablePosts: _replacePost(state.availablePosts, post),
          successMessage: 'Postingan berhasil diperbarui!',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onCloseFoodPostRequested(
    CloseFoodPostRequested event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodPostStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _closeFoodPost(
      CloseFoodPostParams(postId: event.postId, donorId: event.donorId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (post) => emit(
        state.copyWith(
          status: FoodPostStatus.success,
          myPosts: _replacePost(state.myPosts, post),
          availablePosts: state.availablePosts
              .where((availablePost) => availablePost.id != post.id)
              .toList(),
          successMessage: 'Postingan berhasil ditutup',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onDeleteFoodPostRequested(
    DeleteFoodPostRequested event,
    Emitter<FoodPostState> emit,
  ) async {
    final previousMyPosts = state.myPosts;
    final previousAvailablePosts = state.availablePosts;
    final updatedMyPosts = previousMyPosts
        .where((post) => post.id != event.postId)
        .toList();
    final updatedAvailablePosts = previousAvailablePosts
        .where((post) => post.id != event.postId)
        .toList();

    emit(
      state.copyWith(
        status: FoodPostStatus.loading,
        myPosts: updatedMyPosts,
        availablePosts: updatedAvailablePosts,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _deleteFoodPost(
      DeleteFoodPostParams(postId: event.postId, donorId: event.donorId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          myPosts: previousMyPosts,
          availablePosts: previousAvailablePosts,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: FoodPostStatus.success,
          myPosts: updatedMyPosts,
          availablePosts: updatedAvailablePosts,
          successMessage: 'Postingan berhasil dihapus',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onLoadMyFoodPosts(
    LoadMyFoodPosts event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodPostStatus.loadingPosts,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _getMyFoodPosts(event.donorId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: FoodPostStatus.initial,
          myPosts: posts,
          clearSuccess: true,
        ),
      ),
    );
  }

  Future<void> _onLoadAvailableFoodPosts(
    LoadAvailableFoodPosts event,
    Emitter<FoodPostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodPostStatus.loadingPosts,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _getAvailableFoodPosts();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FoodPostStatus.failure,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: FoodPostStatus.initial,
          availablePosts: posts,
          clearSuccess: true,
        ),
      ),
    );
  }

  List<FoodPostEntity> _replacePost(
    List<FoodPostEntity> posts,
    FoodPostEntity updatedPost,
  ) {
    return posts.map((post) {
      return post.id == updatedPost.id ? updatedPost : post;
    }).toList();
  }
}
