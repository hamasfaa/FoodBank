import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbank/features/rating/domain/entities/rating_entity.dart';
import '../models/rating_model.dart';

abstract class RatingRemoteDatasource {
  Future<RatingEntity> createRating({
    required String claimId,
    required String donorId,
    required String receiverId,
    required int score,
    required String comment,
  });
}

class RatingRemoteDatasourceImpl implements RatingRemoteDatasource {
  final FirebaseFirestore _firestore;

  RatingRemoteDatasourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<RatingEntity> createRating({
    required String claimId,
    required String donorId,
    required String receiverId,
    required int score,
    required String comment,
  }) async {
    if (score < 1 || score > 5) {
      throw Exception('Rating harus berada di antara 1 sampai 5 bintang');
    }

    final claimSnapshot = await _firestore
        .collection('claims')
        .doc(claimId)
        .get();
    if (!claimSnapshot.exists) {
      throw Exception('Klaim tidak ditemukan');
    }

    final claimData = claimSnapshot.data()!;
    final claimStatus = claimData['status'] as String? ?? '';
    final isVerifiedByAdmin = claimData['isVerifiedByAdmin'] as bool? ?? false;
    final proofPhotoUrl = claimData['proofPhotoUrl'] as String? ?? '';

    if (claimData['donorId'] != donorId ||
        claimData['receiverId'] != receiverId) {
      throw Exception('Data rating tidak sesuai dengan klaim');
    }

    if (claimStatus != 'verified' ||
        !isVerifiedByAdmin ||
        proofPhotoUrl.trim().isEmpty) {
      throw Exception(
        'Rating hanya bisa diberikan setelah bukti diverifikasi admin',
      );
    }

    final existing = await _firestore
        .collection('ratings')
        .where('claimId', isEqualTo: claimId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Kamu sudah memberikan rating untuk klaim ini');
    }

    const uuid = Uuid();
    final ratingId = uuid.v4();
    final now = DateTime.now();

    final model = RatingModel(
      id: ratingId,
      claimId: claimId,
      donorId: donorId,
      receiverId: receiverId,
      score: score,
      comment: comment,
      createdAt: now,
    );

    await _firestore
        .collection('ratings')
        .doc(ratingId)
        .set(model.toFirestore());
    return model;
  }
}
