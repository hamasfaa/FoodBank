import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/auth/domain/entities/google_auth_outcome.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
import 'package:foodbank/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodbank/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  const AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    try {
      final user = await _datasource.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e.code));
    } catch (_) {
      return const Left(AuthFailure('Terjadi kesalahan, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.login(
        email: email,
        password: password,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e.code));
    } catch (e) {
      return Left(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, GoogleAuthOutcome>> signInWithGoogle() async {
    try {
      final outcome = await _datasource.signInWithGoogle();
      return Right(outcome);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e.code));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('dibatalkan') || msg.contains('12501')) {
        return const Left(AuthFailure('Login Google dibatalkan'));
      }
      return const Left(AuthFailure('Terjadi kesalahan, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> completeGoogleProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    String? photoUrl,
  }) async {
    try {
      final user = await _datasource.completeGoogleProfile(
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        photoUrl: photoUrl,
      );
      return Right(user);
    } catch (_) {
      return const Left(AuthFailure('Gagal menyimpan profil, coba lagi'));
    }
  }

  Failure _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const AuthFailure('Email sudah terdaftar, silakan login');
      case 'weak-password':
        return const AuthFailure('Kata sandi terlalu lemah');
      case 'network-request-failed':
        return const NetworkFailure('Tidak ada koneksi internet');
      case 'account-exists-with-different-credential':
        return const AuthFailure('Email sudah dipakai dengan metode lain');
      default:
        return const AuthFailure('Terjadi kesalahan, coba lagi');
    }
  }
}
