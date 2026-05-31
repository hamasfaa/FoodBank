import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:foodbank/features/auth/domain/entities/google_auth_outcome.dart';
import 'package:foodbank/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  });

  Future<GoogleAuthOutcome> signInWithGoogle();

  Future<UserModel> completeGoogleProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    String? photoUrl,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDatasourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;
    final userModel = UserModel(
      uid: firebaseUser.uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      createdAt: DateTime.now(),
      isActive: true,
    );

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());
      return userModel;
    } catch (e) {
      await firebaseUser.delete();
      rethrow;
    }
  }

  @override
  Future<GoogleAuthOutcome> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw Exception('Login Google dibatalkan');
    }

    final googleAuth = await googleAccount.authentication;

    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      await _googleSignIn.signOut();
      throw Exception('Gagal mendapatkan token Google. Coba lagi.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        return ExistingGoogleUser(UserModel.fromFirestore(doc.data()!));
      }

      return NewGoogleUser(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  @override
  Future<UserModel> completeGoogleProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    String? photoUrl,
  }) async {
    final userModel = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      createdAt: DateTime.now(),
      isActive: true,
      photoUrl: photoUrl,
    );

    await _firestore.collection('users').doc(uid).set(userModel.toFirestore());

    return userModel;
  }
}
