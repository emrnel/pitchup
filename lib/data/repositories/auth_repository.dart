import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../../core/utils/helpers.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService = FirestoreService();

  AuthRepository() {
    // Initialize Google Sign In with proper configuration
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _firestoreService.getUser(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Giriş yapılırken bir hata oluştu: $e');
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: UserRole.entrepreneur, // Default role
          isApproved: false,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(user);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Kayıt olurken bir hata oluştu: $e');
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Clear any previous session
      await _googleSignIn.signOut();

      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google authentication tokens are null');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Firebase authentication failed');
      }

      final firebaseUser = userCredential.user!;

      // Check if user already exists
      var user = await _firestoreService.getUser(firebaseUser.uid);

      if (user == null) {
        // Create new user
        user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? googleUser.email,
          name: firebaseUser.displayName ??
              googleUser.displayName ??
              'Google User',
          role: UserRole.entrepreneur,
          isApproved: false,
          profilePicture: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      throw Exception(
          'Google ile giriş yapılırken bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<UserModel?> signInWithApple() async {
    if (!Helpers.isIOS) {
      throw Exception('Apple Sign In is only available on iOS');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        var user = await _firestoreService.getUser(userCredential.user!.uid);

        if (user == null) {
          final fullName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();

          user = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? appleCredential.email ?? '',
            name: fullName.isNotEmpty ? fullName : 'Apple User',
            role: UserRole.entrepreneur,
            isApproved: false,
            createdAt: DateTime.now(),
          );

          await _firestoreService.createUser(user);
        }

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple ile giriş yapılırken bir hata oluştu: $e');
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _firestoreService.updateUserRole(userId, role);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
      // Force sign out even if there's an error
      await _auth.signOut();
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi şu anda kullanılamıyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemiyle kayıtlı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return e.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
