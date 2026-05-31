import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/features/auth/domain/entities/google_auth_outcome.dart';
import 'package:foodbank/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:foodbank/features/auth/domain/usecases/register_usecase.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_event.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUsecase _registerUsecase;
  final GoogleSignInUsecase _googleSignInUsecase;
  final CompleteProfileUsecase _completeProfileUsecase;

  AuthBloc(
    this._registerUsecase,
    this._googleSignInUsecase,
    this._completeProfileUsecase,
  ) : super(const AuthState()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<CompleteProfileSubmitted>(_onCompleteProfileSubmitted);
    on<RoleSelected>(_onRoleSelected);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<ConfirmPasswordVisibilityToggled>(_onConfirmPasswordVisibilityToggled);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _registerUsecase(
      RegisterParams(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        role: event.role,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          clearUser: true,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.success,
          user: user,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _googleSignInUsecase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (outcome) {
        if (outcome is ExistingGoogleUser) {
          emit(
            state.copyWith(
              status: AuthStatus.success,
              user: outcome.user,
              clearError: true,
              clearPending: true,
            ),
          );
        } else if (outcome is NewGoogleUser) {
          emit(
            state.copyWith(
              status: AuthStatus.needsProfile,
              pendingUid: outcome.uid,
              pendingName: outcome.displayName,
              pendingEmail: outcome.email,
              pendingPhotoUrl: outcome.photoUrl,
              clearError: true,
              selectedRole: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCompleteProfileSubmitted(
    CompleteProfileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _completeProfileUsecase(
      CompleteProfileParams(
        uid: state.pendingUid!,
        fullName: event.fullName,
        email: state.pendingEmail!,
        phoneNumber: event.phoneNumber,
        role: event.role,
        photoUrl: state.pendingPhotoUrl,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.needsProfile,
          errorMessage: failure.message,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.success,
          user: user,
          clearError: true,
          clearPending: true,
        ),
      ),
    );
  }

  void _onRoleSelected(RoleSelected event, Emitter<AuthState> emit) {
    emit(state.copyWith(selectedRole: event.role));
  }

  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void _onConfirmPasswordVisibilityToggled(
    ConfirmPasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible),
    );
  }
}
