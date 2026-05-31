import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
abstract class GoogleAuthOutcome {
  const GoogleAuthOutcome();
}

class ExistingGoogleUser extends GoogleAuthOutcome {
  final UserEntity user;
  const ExistingGoogleUser(this.user);
}

class NewGoogleUser extends GoogleAuthOutcome {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const NewGoogleUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}
