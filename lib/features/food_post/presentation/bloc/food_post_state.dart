import 'package:equatable/equatable.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';

enum FoodPostStatus { initial, loading, success, failure, loadingPosts }

class FoodPostState extends Equatable {
  final FoodPostStatus status;
  final List<FoodPostEntity> myPosts;
  final List<FoodPostEntity> availablePosts;
  final String? errorMessage;

  const FoodPostState({
    this.status = FoodPostStatus.initial,
    this.myPosts = const [],
    this.availablePosts = const [],
    this.errorMessage,
  });

  FoodPostState copyWith({
    FoodPostStatus? status,
    List<FoodPostEntity>? myPosts,
    List<FoodPostEntity>? availablePosts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodPostState(
      status: status ?? this.status,
      myPosts: myPosts ?? this.myPosts,
      availablePosts: availablePosts ?? this.availablePosts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, myPosts, availablePosts, errorMessage];
}
