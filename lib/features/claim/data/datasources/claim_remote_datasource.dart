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

  Future<List<ClaimEntity>> getIncomingClaims(String donorId);

  Future<void> cancelClaim(String claimId);

  Future<void> confirmClaim({required String claimId, required String donorId});

  Future<void> rejectClaim({required String claimId, required String donorId});
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
  Future<List<ClaimEntity>> getIncomingClaims(String donorId) async {
    final snapshot = await _firestore
        .collection('claims')
        .where('donorId', isEqualTo: donorId)
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

  @override
  Future<void> confirmClaim({
    required String claimId,
    required String donorId,
  }) async {
    final claimRef = _firestore.collection('claims').doc(claimId);
    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists) {
      throw Exception('Klaim tidak ditemukan');
    }

    final selectedClaim = ClaimModel.fromFirestore(claimSnapshot);
    if (selectedClaim.donorId != donorId) {
      throw Exception('Kamu tidak punya akses ke klaim ini');
    }
    if (selectedClaim.status != 'pending') {
      throw Exception('Hanya klaim pending yang bisa dikonfirmasi');
    }

    final pendingClaims = await _firestore
        .collection('claims')
        .where('foodId', isEqualTo: selectedClaim.foodId)
        .where('status', isEqualTo: 'pending')
        .get();

    final now = Timestamp.now();
    final batch = _firestore.batch();

    for (final doc in pendingClaims.docs) {
      if (doc.id == claimId) {
        batch.update(doc.reference, {
          'status': 'confirmed',
          'confirmedAt': now,
        });
      } else {
        batch.update(doc.reference, {'status': 'cancelled'});
      }
    }

    batch.update(
      _firestore.collection('food_posts').doc(selectedClaim.foodId),
      {'status': 'claimed'},
    );

    await batch.commit();
  }

  @override
  Future<void> rejectClaim({
    required String claimId,
    required String donorId,
  }) async {
    final claimRef = _firestore.collection('claims').doc(claimId);
    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists) {
      throw Exception('Klaim tidak ditemukan');
    }

    final claim = ClaimModel.fromFirestore(claimSnapshot);
    if (claim.donorId != donorId) {
      throw Exception('Kamu tidak punya akses ke klaim ini');
    }
    if (claim.status != 'pending') {
      throw Exception('Hanya klaim pending yang bisa ditolak');
    }

    await claimRef.update({'status': 'cancelled'});
  }
}
