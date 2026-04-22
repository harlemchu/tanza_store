import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

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

  // Add Facebook Sign-In
  // Future<User?> signInWithFacebook() async {
  //   try {
  //     final LoginResult result = await _facebookAuth.login();
  //     if (result.status == LoginStatus.success) {
  //       final OAuthCredential credential = FacebookAuthProvider.credential(
  //         result.accessToken!.tokenString,
  //       );
  //       final UserCredential userCredential =
  //           await _auth.signInWithCredential(credential);
  //       return userCredential.user;
  //     }
  //     return null;
  //   } catch (e) {
  //     debugPrint('Facebook Sign-In error: $e');
  //     return null;
  //   }
  // }
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status != LoginStatus.success) return null;

      final userData = await _facebookAuth.getUserData(
        fields: "id,name,email,picture.width(500).height(500)",
      );
      final String? photoUrl = userData['picture']?['data']?['url'];
      final String? name = userData['name'];
      final String? email = userData['email'];

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // Instead of returning null, throw a meaningful error
          throw Exception('An account already exists with $email.\n\n'
              'Please sign in with Google first, then go to Profile Settings to link your Facebook account.');
        }
        rethrow;
      }

      User? user = userCredential.user;
      if (user != null) {
        if (name != null) await user.updateDisplayName(name);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();
        user = _auth.currentUser;
      }
      return user;
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      // Re‑throw the exception so the LoginScreen can display it
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
    await _auth.signOut();
  }

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}
