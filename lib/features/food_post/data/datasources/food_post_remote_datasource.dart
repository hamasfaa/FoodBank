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

  Future<List<FoodPostEntity>> getMyFoodPosts(String donorId);

  Future<List<FoodPostEntity>> getAvailableFoodPosts();
}

class FoodPostRemoteDatasourceImpl implements FoodPostRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FoodPostRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
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
      final ref = _storage.ref().child('food_posts/$donorId/${postId}_${entry.key}.jpg');
      await ref.putFile(entry.value, SettableMetadata(contentType: 'image/jpeg'));
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

    await _firestore.collection('food_posts').doc(postId).set(model.toFirestore());
    return model;
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
}
