import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('Step 1: Initiating Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Step 2: User cancelled sign-in');
        return null;
      }
      debugPrint('Step 2: User selected: ${googleUser.email}');

      debugPrint('Step 3: Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('Step 4: Creating credential...');
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Step 5: Signing in with Firebase...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      debugPrint(
          'Step 6: Sign-in successful! User: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}
