import 'package:dartz/dartz.dart';
import 'package:foodbank/core/errors/failures.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import 'package:foodbank/features/claim/domain/repositories/claim_repository.dart';
import '../datasources/claim_remote_datasource.dart';

class ClaimRepositoryImpl implements ClaimRepository {
  final ClaimRemoteDatasource _datasource;

  const ClaimRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, ClaimEntity>> createClaim({
    required String foodId,
    required String foodTitle,
    required String foodImageUrl,
    required String donorId,
    required String donorName,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      final claim = await _datasource.createClaim(
        foodId: foodId,
        foodTitle: foodTitle,
        foodImageUrl: foodImageUrl,
        donorId: donorId,
        donorName: donorName,
        receiverId: receiverId,
        receiverName: receiverName,
      );
      return Right(claim);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, List<ClaimEntity>>> getMyClaims(
    String receiverId,
  ) async {
    try {
      final claims = await _datasource.getMyClaims(receiverId);
      return Right(claims);
    } catch (e) {
      return const Left(ServerFailure('Gagal memuat klaim, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, List<ClaimEntity>>> getIncomingClaims(
    String donorId,
  ) async {
    try {
      final claims = await _datasource.getIncomingClaims(donorId);
      return Right(claims);
    } catch (e) {
      return const Left(ServerFailure('Gagal memuat klaim masuk, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelClaim(String claimId) async {
    try {
      await _datasource.cancelClaim(claimId);
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Gagal membatalkan klaim, coba lagi'));
    }
  }

  @override
  Future<Either<Failure, void>> confirmClaim({
    required String claimId,
    required String donorId,
  }) async {
    try {
      await _datasource.confirmClaim(claimId: claimId, donorId: donorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> rejectClaim({
    required String claimId,
    required String donorId,
  }) async {
    try {
      await _datasource.rejectClaim(claimId: claimId, donorId: donorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
