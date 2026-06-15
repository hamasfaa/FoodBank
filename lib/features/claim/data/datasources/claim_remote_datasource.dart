import 'dart:async';

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
    unawaited(
      _createNotification(
        recipientId: donorId,
        senderId: receiverId,
        senderName: receiverName,
        type: 'claim_incoming',
        title: 'Klaim Baru Masuk',
        body:
            '$receiverName ingin mengambil $foodTitle. Buka FoodBridge untuk konfirmasi.',
        data: {'claimId': claimId, 'foodId': foodId, 'receiverId': receiverId},
      ),
    );

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
    final claimRef = _firestore.collection('claims').doc(claimId);
    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists) {
      throw Exception('Klaim tidak ditemukan');
    }

    final claim = ClaimModel.fromFirestore(claimSnapshot);
    if (claim.status != 'pending' && claim.status != 'confirmed') {
      throw Exception('Klaim ini sudah tidak bisa dibatalkan');
    }

    await claimRef.update({'status': 'cancelled'});
    unawaited(
      _createNotification(
        recipientId: claim.donorId,
        senderId: claim.receiverId,
        senderName: claim.receiverName,
        type: 'claim_cancelled_by_receiver',
        title: 'Klaim Dibatalkan',
        body: '${claim.receiverName} membatalkan klaim ${claim.foodTitle}.',
        data: {
          'claimId': claim.id,
          'foodId': claim.foodId,
          'receiverId': claim.receiverId,
        },
      ),
    );
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

    final pendingClaimsSnapshot = await _firestore
        .collection('claims')
        .where('foodId', isEqualTo: selectedClaim.foodId)
        .where('status', isEqualTo: 'pending')
        .get();
    final pendingClaims = pendingClaimsSnapshot.docs
        .map((doc) => ClaimModel.fromFirestore(doc))
        .toList();

    final now = Timestamp.now();
    final batch = _firestore.batch();

    for (final claim in pendingClaims) {
      final ref = _firestore.collection('claims').doc(claim.id);
      if (claim.id == claimId) {
        batch.update(ref, {'status': 'confirmed', 'confirmedAt': now});
      } else {
        batch.update(ref, {'status': 'cancelled'});
      }
    }

    batch.update(
      _firestore.collection('food_posts').doc(selectedClaim.foodId),
      {'status': 'claimed'},
    );

    await batch.commit();
    unawaited(
      _createNotification(
        recipientId: selectedClaim.receiverId,
        senderId: selectedClaim.donorId,
        senderName: selectedClaim.donorName,
        type: 'claim_confirmed',
        title: 'Klaim Diterima',
        body:
            'Donor menyetujui klaim ${selectedClaim.foodTitle}. Segera cek detail pickup di FoodBridge.',
        data: {
          'claimId': selectedClaim.id,
          'foodId': selectedClaim.foodId,
          'donorId': selectedClaim.donorId,
        },
      ),
    );
    for (final claim in pendingClaims.where((claim) => claim.id != claimId)) {
      unawaited(
        _createNotification(
          recipientId: claim.receiverId,
          senderId: selectedClaim.donorId,
          senderName: selectedClaim.donorName,
          type: 'claim_not_selected',
          title: 'Klaim Tidak Dipilih',
          body:
              'Klaim ${claim.foodTitle} sudah diterima oleh penerima lain. Cek makanan lain yang tersedia.',
          data: {
            'claimId': claim.id,
            'foodId': claim.foodId,
            'donorId': selectedClaim.donorId,
          },
        ),
      );
    }
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
    unawaited(
      _createNotification(
        recipientId: claim.receiverId,
        senderId: claim.donorId,
        senderName: claim.donorName,
        type: 'claim_rejected',
        title: 'Klaim Belum Disetujui',
        body:
            'Maaf, klaim ${claim.foodTitle} belum bisa diproses. Cek makanan lain yang tersedia.',
        data: {
          'claimId': claim.id,
          'foodId': claim.foodId,
          'donorId': claim.donorId,
        },
      ),
    );
  }

  Future<void> _createNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': senderId,
        'senderName': senderName,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'deliveredAt': null,
        'readAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Klaim tetap harus berhasil walaupun notifikasi realtime gagal dibuat.
    }
  }
}
