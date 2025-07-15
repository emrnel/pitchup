import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static Future<String?> getCurrentUserToken() async {
    return await currentUser?.getIdToken();
  }

  static Future<void> refreshToken() async {
    await currentUser?.getIdToken(true);
  }

  static Future<bool> verifyPassword(String password) async {
    if (currentUser == null || currentUser!.email == null) return false;

    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    await currentUser?.updatePassword(newPassword);
  }

  static Future<void> updateEmail(String newEmail) async {
    await currentUser?.updateEmail(newEmail);
  }

  static Future<void> deleteAccount() async {
    await currentUser?.delete();
  }
}
