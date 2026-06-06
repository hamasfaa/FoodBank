import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:foodbank/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:foodbank/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodbank/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/login_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/register_usecase.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/food_post/data/datasources/food_post_remote_datasource.dart';
import 'package:foodbank/features/food_post/data/repositories/food_post_repository_impl.dart';
import 'package:foodbank/features/food_post/domain/repositories/food_post_repository.dart';
import 'package:foodbank/features/food_post/domain/usecases/create_food_post_usecase.dart';
import 'package:foodbank/features/food_post/domain/usecases/get_my_food_posts_usecase.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

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

  sl.registerLazySingleton<FoodPostRepository>(
    () => FoodPostRepositoryImpl(sl<FoodPostRemoteDatasource>()),
  );

  sl.registerLazySingleton<CreateFoodPostUsecase>(
    () => CreateFoodPostUsecase(sl<FoodPostRepository>()),
  );

  sl.registerLazySingleton<GetMyFoodPostsUsecase>(
    () => GetMyFoodPostsUsecase(sl<FoodPostRepository>()),
  );

  sl.registerFactory<FoodPostBloc>(
    () =>
        FoodPostBloc(sl<CreateFoodPostUsecase>(), sl<GetMyFoodPostsUsecase>()),
  );
}
