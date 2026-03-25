import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ─── Stream ───────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Email/Password Sign Up ───────────────────────────────────
  Future<({User user, bool isNewUser})> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    await user.updateDisplayName(name);

    // Create Firestore user document
    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toFirestore());

    return (user: user, isNewUser: true);
  }

  // ─── Email/Password Login ────────────────────────────────────
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  // ─── Google Sign-In ──────────────────────────────────────────
  Future<({User user, bool isNewUser})> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    // Create Firestore document only for new users
    if (isNewUser) {
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());
    }

    return (user: user, isNewUser: isNewUser);
  }

  // ─── Password Reset ──────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Role ────────────────────────────────────────────────────
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
