import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbank/features/food_post/domain/entities/food_location_entity.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import '../models/food_post_model.dart';

abstract class FoodPostRemoteDatasource {
  Future<FoodPostEntity> createFoodPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<File> images,
  });

  Future<FoodPostEntity> updateFoodPost({
    required String postId,
    required String donorId,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<String> existingImageUrls,
    required List<File> newImages,
  });

  Future<FoodPostEntity> closeFoodPost({
    required String postId,
    required String donorId,
  });

  Future<void> deleteFoodPost({
    required String postId,
    required String donorId,
  });

  Future<List<FoodPostEntity>> getMyFoodPosts(String donorId);

  Future<List<FoodPostEntity>> getAvailableFoodPosts();
}

class FoodPostRemoteDatasourceImpl implements FoodPostRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FoodPostRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  @override
  Future<FoodPostEntity> createFoodPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<File> images,
  }) async {
    const uuid = Uuid();
    final postId = uuid.v4();

    final uploadTasks = images.asMap().entries.map((entry) async {
      final ref = _storage.ref().child(
        'food_posts/$donorId/${postId}_${entry.key}.jpg',
      );
      await ref.putFile(
        entry.value,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return ref.getDownloadURL();
    });
    final imageUrls = await Future.wait(uploadTasks);

    final now = DateTime.now();
    final model = FoodPostModel(
      id: postId,
      title: title,
      description: description,
      quantity: quantity,
      expiredAt: expiredAt,
      status: 'available',
      location: location,
      imageUrls: imageUrls,
      createdAt: now,
      donorId: donorId,
      donorName: donorName,
    );

    await _firestore
        .collection('food_posts')
        .doc(postId)
        .set(model.toFirestore());
    return model;
  }

  @override
  Future<FoodPostEntity> updateFoodPost({
    required String postId,
    required String donorId,
    required String title,
    required String description,
    required double quantity,
    required DateTime expiredAt,
    required FoodLocationEntity location,
    required List<String> existingImageUrls,
    required List<File> newImages,
  }) async {
    final docRef = _firestore.collection('food_posts').doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Postingan tidak ditemukan');
    }

    final current = FoodPostModel.fromFirestore(snapshot);
    _ensureOwnedByDonor(current, donorId);

    if (current.status != 'available') {
      throw Exception('Postingan yang sudah tidak tersedia tidak bisa diedit');
    }

    final retainedUrls = existingImageUrls
        .where((url) => current.imageUrls.contains(url))
        .toList();
    final uploadedUrls = await _uploadImages(
      donorId: donorId,
      postId: postId,
      images: newImages,
      startIndex: retainedUrls.length,
    );
    final imageUrls = [...retainedUrls, ...uploadedUrls];

    if (imageUrls.isEmpty) {
      throw Exception('Pilih minimal 1 foto makanan');
    }

    final updated = FoodPostModel(
      id: current.id,
      title: title,
      description: description,
      quantity: quantity,
      expiredAt: expiredAt,
      status: current.status,
      location: location,
      imageUrls: imageUrls,
      createdAt: current.createdAt,
      donorId: current.donorId,
      donorName: current.donorName,
    );

    await docRef.update(updated.toFirestore());

    final removedUrls = current.imageUrls
        .where((url) => !retainedUrls.contains(url))
        .toList();
    if (removedUrls.isNotEmpty) {
      unawaited(_deleteImageUrls(removedUrls));
    }

    return updated;
  }

  @override
  Future<FoodPostEntity> closeFoodPost({
    required String postId,
    required String donorId,
  }) async {
    final docRef = _firestore.collection('food_posts').doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Postingan tidak ditemukan');
    }

    final current = FoodPostModel.fromFirestore(snapshot);
    _ensureOwnedByDonor(current, donorId);

    if (current.status != 'available') {
      throw Exception('Hanya postingan tersedia yang bisa ditutup');
    }

    final pendingClaims = await _firestore
        .collection('claims')
        .where('foodId', isEqualTo: postId)
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();
    batch.update(docRef, {'status': 'closed'});
    for (final claim in pendingClaims.docs) {
      batch.update(claim.reference, {'status': 'cancelled'});
    }
    await batch.commit();

    return FoodPostModel(
      id: current.id,
      title: current.title,
      description: current.description,
      quantity: current.quantity,
      expiredAt: current.expiredAt,
      status: 'closed',
      location: current.location,
      imageUrls: current.imageUrls,
      createdAt: current.createdAt,
      donorId: current.donorId,
      donorName: current.donorName,
    );
  }

  @override
  Future<void> deleteFoodPost({
    required String postId,
    required String donorId,
  }) async {
    final docRef = _firestore.collection('food_posts').doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Postingan tidak ditemukan');
    }

    final current = FoodPostModel.fromFirestore(snapshot);
    _ensureOwnedByDonor(current, donorId);

    final claims = await _firestore
        .collection('claims')
        .where('foodId', isEqualTo: postId)
        .limit(1)
        .get();

    if (claims.docs.isNotEmpty) {
      throw Exception('Postingan sudah memiliki klaim, tutup postingan saja');
    }

    await docRef.delete();
    await _deleteImageUrls(current.imageUrls);
  }

  @override
  Future<List<FoodPostEntity>> getAvailableFoodPosts() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('food_posts')
        .where('status', isEqualTo: 'available')
        .get();

    final posts = snapshot.docs
        .map((doc) => FoodPostModel.fromFirestore(doc))
        .where((post) => post.expiredAt.isAfter(now))
        .toList();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  @override
  Future<List<FoodPostEntity>> getMyFoodPosts(String donorId) async {
    final snapshot = await _firestore
        .collection('food_posts')
        .where('donorId', isEqualTo: donorId)
        .get();

    final now = DateTime.now();
    final batch = _firestore.batch();
    bool hasBatchUpdates = false;

    final posts = snapshot.docs.map((doc) {
      var post = FoodPostModel.fromFirestore(doc);
      if (post.status == 'available' && post.expiredAt.isBefore(now)) {
        batch.update(doc.reference, {'status': 'expired'});
        hasBatchUpdates = true;
        post = FoodPostModel(
          id: post.id,
          title: post.title,
          description: post.description,
          quantity: post.quantity,
          expiredAt: post.expiredAt,
          status: 'expired',
          location: post.location,
          imageUrls: post.imageUrls,
          createdAt: post.createdAt,
          donorId: post.donorId,
          donorName: post.donorName,
        );
      }
      return post;
    }).toList();

    if (hasBatchUpdates) unawaited(batch.commit());

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<String>> _uploadImages({
    required String donorId,
    required String postId,
    required List<File> images,
    int startIndex = 0,
  }) async {
    final uploadStamp = DateTime.now().microsecondsSinceEpoch;
    final uploadTasks = images.asMap().entries.map((entry) async {
      final ref = _storage.ref().child(
        'food_posts/$donorId/${postId}_${uploadStamp}_${startIndex + entry.key}.jpg',
      );
      await ref.putFile(
        entry.value,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return ref.getDownloadURL();
    });
    return Future.wait(uploadTasks);
  }

  Future<void> _deleteImageUrls(List<String> imageUrls) async {
    await Future.wait(
      imageUrls.map((url) async {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {
          // Ignore missing/invalid storage objects so Firestore stays authoritative.
        }
      }),
    );
  }

  void _ensureOwnedByDonor(FoodPostEntity post, String donorId) {
    if (post.donorId != donorId) {
      throw Exception('Kamu tidak punya akses ke postingan ini');
    }
  }
}
