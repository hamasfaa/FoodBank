import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.role,
    required super.createdAt,
    required super.isActive,
    super.photoUrl,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      fullName: data['fullName'] as String,
      email: data['email'] as String,
      phoneNumber: data['phoneNumber'] as String,
      role: data['role'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
