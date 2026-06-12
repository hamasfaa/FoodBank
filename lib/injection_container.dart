import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:foodbank/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:foodbank/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodbank/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/login_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/register_usecase.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:foodbank/features/food_post/data/datasources/gemini_food_recognition_remote_datasource.dart';
import 'package:foodbank/features/food_post/data/datasources/food_recognition_remote_datasource.dart';
import 'package:foodbank/features/food_post/data/datasources/food_post_remote_datasource.dart';
import 'package:foodbank/features/food_post/data/repositories/food_recognition_repository_impl.dart';
import 'package:foodbank/features/food_post/data/repositories/food_post_repository_impl.dart';
import 'package:foodbank/features/food_post/domain/repositories/food_recognition_repository.dart';
import 'package:foodbank/features/food_post/domain/repositories/food_post_repository.dart';
import 'package:foodbank/features/food_post/domain/usecases/close_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/create_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/delete_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_available_food_posts_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_my_food_posts_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/recognize_food_image_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/update_food_post_usecase.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';

import 'package:foodbank/features/claim/data/datasources/claim_remote_datasource.dart';
import 'package:foodbank/features/claim/data/repositories/claim_repository_impl.dart';
import 'package:foodbank/features/claim/domain/repositories/claim_repository.dart';
import 'package:foodbank/features/claim/domain/usecases/cancel_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/create_claim_usecase.dart';
import 'package:foodbank/features/claim/domain/usecases/get_my_claims_usecase.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_bloc.dart';

import 'package:foodbank/features/rating/data/datasources/rating_remote_datasource.dart';
import 'package:foodbank/features/rating/data/repositories/rating_repository_impl.dart';
import 'package:foodbank/features/rating/domain/repositories/rating_repository.dart';
import 'package:foodbank/features/rating/domain/usecases/create_rating_usecase.dart';
import 'package:foodbank/features/rating/presentation/bloc/rating_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Auth feature
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDatasource>()),
  );
  sl.registerLazySingleton<RegisterUsecase>(
    () => RegisterUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GoogleSignInUsecase>(
    () => GoogleSignInUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CompleteProfileUsecase>(
    () => CompleteProfileUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      sl<RegisterUsecase>(),
      sl<LoginUsecase>(),
      sl<GoogleSignInUsecase>(),
      sl<CompleteProfileUsecase>(),
    ),
  );

  // Food Post feature
  sl.registerLazySingleton<FoodPostRemoteDatasource>(
    () => FoodPostRemoteDatasourceImpl(
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<FoodRecognitionRemoteDatasource>(
    () => GeminiFoodRecognitionRemoteDatasourceImpl(client: sl<http.Client>()),
  );
  sl.registerLazySingleton<FoodPostRepository>(
    () => FoodPostRepositoryImpl(sl<FoodPostRemoteDatasource>()),
  );
  sl.registerLazySingleton<FoodRecognitionRepository>(
    () => FoodRecognitionRepositoryImpl(sl<FoodRecognitionRemoteDatasource>()),
  );
  sl.registerLazySingleton<CreateFoodPostUsecase>(
    () => CreateFoodPostUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<GetMyFoodPostsUsecase>(
    () => GetMyFoodPostsUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<GetAvailableFoodPostsUsecase>(
    () => GetAvailableFoodPostsUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<UpdateFoodPostUsecase>(
    () => UpdateFoodPostUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<CloseFoodPostUsecase>(
    () => CloseFoodPostUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<DeleteFoodPostUsecase>(
    () => DeleteFoodPostUsecase(sl<FoodPostRepository>()),
  );
  sl.registerLazySingleton<RecognizeFoodImageUsecase>(
    () => RecognizeFoodImageUsecase(sl<FoodRecognitionRepository>()),
  );
  sl.registerFactory<FoodPostBloc>(
    () => FoodPostBloc(
      sl<CreateFoodPostUsecase>(),
      sl<GetMyFoodPostsUsecase>(),
      sl<GetAvailableFoodPostsUsecase>(),
      sl<UpdateFoodPostUsecase>(),
      sl<CloseFoodPostUsecase>(),
      sl<DeleteFoodPostUsecase>(),
    ),
  );

  // Claim feature
  sl.registerLazySingleton<ClaimRemoteDatasource>(
    () => ClaimRemoteDatasourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ClaimRepository>(
    () => ClaimRepositoryImpl(sl<ClaimRemoteDatasource>()),
  );
  sl.registerLazySingleton<CreateClaimUsecase>(
    () => CreateClaimUsecase(sl<ClaimRepository>()),
  );
  sl.registerLazySingleton<GetMyClaimsUsecase>(
    () => GetMyClaimsUsecase(sl<ClaimRepository>()),
  );
  sl.registerLazySingleton<CancelClaimUsecase>(
    () => CancelClaimUsecase(sl<ClaimRepository>()),
  );
  sl.registerFactory<ClaimBloc>(
    () => ClaimBloc(
      sl<CreateClaimUsecase>(),
      sl<GetMyClaimsUsecase>(),
      sl<CancelClaimUsecase>(),
    ),
  );

  // Rating feature
  sl.registerLazySingleton<RatingRemoteDatasource>(
    () => RatingRemoteDatasourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(sl<RatingRemoteDatasource>()),
  );
  sl.registerLazySingleton<CreateRatingUsecase>(
    () => CreateRatingUsecase(sl<RatingRepository>()),
  );
  sl.registerFactory<RatingBloc>(() => RatingBloc(sl<CreateRatingUsecase>()));
}
