import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final DateTime createdAt;
  final bool isActive;
  final String? photoUrl;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.isActive,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        phoneNumber,
        role,
        createdAt,
        isActive,
        photoUrl,
      ];
}
