import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final authServiceProvider = Provider<AuthService>((ref) {
  try {
    return AuthService();
  } catch (e) {
    return AuthService.uninitialized();
  }
});

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (service.isUninitialized) {
    // If Firebase is not initialized, return a stream that emits null
    // so the AuthGate shows the Landing Page instead of hanging in loading state.
    return Stream.value(null);
  }
  return service.authStateChanges;
});

class AuthService {
  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;
  final bool isUninitialized;

  AuthService()
    : _auth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn(
        clientId:
            '102143585564-cbqli8jknkeof0oqb9fao4ttancq8s7v.apps.googleusercontent.com',
      ),
      isUninitialized = false;

  AuthService.uninitialized()
    : _auth = null,
      _googleSignIn = null,
      isUninitialized = true;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    if (isUninitialized || _auth == null) {
      throw Exception("Firebase not initialized. Check your configuration.");
    }

    try {
      if (kIsWeb) {
        // On Web, use Firebase's native popup flow which is more reliable
        // and provides the required ID Token automatically.
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // This handles both Google Sign-In and Firebase linking in one step
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // On Mobile/Desktop, continue using the google_sign_in package
        if (_googleSignIn == null) {
          throw Exception("Google Sign-In not initialized.");
        }
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (isUninitialized) return;
    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _auth?.currentUser?.getIdToken(forceRefresh);
  }
}
