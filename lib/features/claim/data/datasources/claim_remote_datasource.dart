import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import '../models/claim_model.dart';

abstract class ClaimRemoteDatasource {
  Future<ClaimEntity> createClaim({
    required String foodId,
    required String foodTitle,
    required String foodImageUrl,
    required String donorId,
    required String donorName,
    required String receiverId,
    required String receiverName,
  });

  Future<List<ClaimEntity>> getMyClaims(String receiverId);

  Future<void> cancelClaim(String claimId);
}

class ClaimRemoteDatasourceImpl implements ClaimRemoteDatasource {
  final FirebaseFirestore _firestore;

  ClaimRemoteDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<ClaimEntity> createClaim({
    required String foodId,
    required String foodTitle,
    required String foodImageUrl,
    required String donorId,
    required String donorName,
    required String receiverId,
    required String receiverName,
  }) async {
    // Validasi: 1 receiver hanya boleh punya 1 klaim aktif per food
    final existing = await _firestore
        .collection('claims')
        .where('foodId', isEqualTo: foodId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Kamu sudah punya klaim aktif untuk makanan ini');
    }

    const uuid = Uuid();
    final claimId = uuid.v4();
    final now = DateTime.now();

    final model = ClaimModel(
      id: claimId,
      foodId: foodId,
      foodTitle: foodTitle,
      foodImageUrl: foodImageUrl,
      donorId: donorId,
      donorName: donorName,
      receiverId: receiverId,
      receiverName: receiverName,
      status: 'pending',
      claimedAt: now,
    );

    await _firestore.collection('claims').doc(claimId).set(model.toFirestore());
    return model;
  }

  @override
  Future<List<ClaimEntity>> getMyClaims(String receiverId) async {
    final snapshot = await _firestore
        .collection('claims')
        .where('receiverId', isEqualTo: receiverId)
        .get();

    final claims = snapshot.docs
        .map((doc) => ClaimModel.fromFirestore(doc))
        .toList();

    claims.sort((a, b) => b.claimedAt.compareTo(a.claimedAt));
    return claims;
  }

  @override
  Future<void> cancelClaim(String claimId) async {
    await _firestore.collection('claims').doc(claimId).update({
      'status': 'cancelled',
    });
  }
}
