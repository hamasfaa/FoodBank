import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:foodbank/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:foodbank/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodbank/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/register_usecase.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Data sources
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDatasource>()),
  );

  // Use cases
  sl.registerLazySingleton<RegisterUsecase>(
    () => RegisterUsecase(sl<AuthRepository>()),
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
      sl<GoogleSignInUsecase>(),
      sl<CompleteProfileUsecase>(),
    ),
  );
}
