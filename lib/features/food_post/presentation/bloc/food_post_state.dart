import 'package:equatable/equatable.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';

enum FoodPostStatus { initial, loading, success, failure, loadingPosts }

class FoodPostState extends Equatable {
  final FoodPostStatus status;
  final List<FoodPostEntity> myPosts;
  final List<FoodPostEntity> availablePosts;
  final String? errorMessage;
  final String? successMessage;

  const FoodPostState({
    this.status = FoodPostStatus.initial,
    this.myPosts = const [],
    this.availablePosts = const [],
    this.errorMessage,
    this.successMessage,
  });

  FoodPostState copyWith({
    FoodPostStatus? status,
    List<FoodPostEntity>? myPosts,
    List<FoodPostEntity>? availablePosts,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FoodPostState(
      status: status ?? this.status,
      myPosts: myPosts ?? this.myPosts,
      availablePosts: availablePosts ?? this.availablePosts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    myPosts,
    availablePosts,
    errorMessage,
    successMessage,
  ];
}
