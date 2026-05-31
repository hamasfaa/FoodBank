import 'package:equatable/equatable.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, success, failure, needsProfile }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String? selectedRole;

  final String? pendingUid;
  final String? pendingName;
  final String? pendingEmail;
  final String? pendingPhotoUrl;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.selectedRole,
    this.pendingUid,
    this.pendingName,
    this.pendingEmail,
    this.pendingPhotoUrl,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    String? selectedRole,
    String? pendingUid,
    String? pendingName,
    String? pendingEmail,
    String? pendingPhotoUrl,
    bool clearError = false,
    bool clearUser = false,
    bool clearPending = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      selectedRole: selectedRole ?? this.selectedRole,
      pendingUid: clearPending ? null : (pendingUid ?? this.pendingUid),
      pendingName: clearPending ? null : (pendingName ?? this.pendingName),
      pendingEmail: clearPending ? null : (pendingEmail ?? this.pendingEmail),
      pendingPhotoUrl: clearPending
          ? null
          : (pendingPhotoUrl ?? this.pendingPhotoUrl),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    isPasswordVisible,
    isConfirmPasswordVisible,
    selectedRole,
    pendingUid,
    pendingName,
    pendingEmail,
    pendingPhotoUrl,
  ];
}
