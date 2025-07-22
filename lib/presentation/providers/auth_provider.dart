// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firestore_service.dart';
import '../../core/managers/analytics_manager.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isInvestor => _currentUser?.role == UserRole.investor;
  bool get isEntrepreneur => _currentUser?.role == UserRole.entrepreneur;
  bool get isApprovedInvestor =>
      isInvestor && (_currentUser?.isApproved ?? false);

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('AuthProvider: Initializing...');
      _setLoading(true);

      // Listen to auth state changes
      _authRepository.authStateChanges.listen((User? user) async {
        debugPrint('AuthProvider: Auth state changed - User: ${user?.uid}');

        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          _currentUser = null;
          debugPrint('AuthProvider: User signed out');
          notifyListeners();
        }
      });

      // Check if user is already logged in
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser != null) {
        debugPrint('AuthProvider: Found existing user: ${firebaseUser.uid}');
        await _loadUserData(firebaseUser.uid);
      } else {
        debugPrint('AuthProvider: No existing user found');
      }
    } catch (e) {
      debugPrint('AuthProvider: Initialization error: $e');
      _setError('Initialization failed: $e');
    } finally {
      _isInitialized = true;
      _setLoading(false);
      debugPrint(
          'AuthProvider: Initialization complete. Initialized: $_isInitialized');
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      debugPrint('AuthProvider: Loading user data for: $userId');
      final user = await _firestoreService.getUser(userId);

      if (user != null) {
        _currentUser = user;
        _clearError();
        debugPrint('AuthProvider: User data loaded successfully: ${user.name}');
      } else {
        debugPrint('AuthProvider: User data not found in Firestore');
        _setError('User data not found');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error loading user data: $e');
      _setError('Failed to load user data: $e');
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthProvider: Attempting email sign in for: $email');
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        debugPrint('AuthProvider: Email sign in successful');

        // Analytics
        await AnalyticsManager.instance.logLogin('email');
        await AnalyticsManager.instance.setUserId(user.id);
        await AnalyticsManager.instance.setUserProperty(
          name: 'user_role',
          value: user.role.toString().split('.').last,
        );

        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Email sign in returned null user');
        _setError('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.');
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Email sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    debugPrint('AuthProvider: Attempting email sign up for: $email');
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        _currentUser = user;
        debugPrint('AuthProvider: Email sign up successful');

        // Analytics
        await AnalyticsManager.instance.logSignUp('email');
        await AnalyticsManager.instance.setUserId(user.id);

        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Email sign up returned null user');
        _setError('Kayıt başarısız. Lütfen tekrar deneyin.');
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Email sign up error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('AuthProvider: Attempting Google sign in');
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        debugPrint('AuthProvider: Google sign in successful for: ${user.name}');

        // Analytics
        await AnalyticsManager.instance.logLogin('google');
        await AnalyticsManager.instance.setUserId(user.id);
        await AnalyticsManager.instance.setUserProperty(
          name: 'user_role',
          value: user.role.toString().split('.').last,
        );

        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Google sign in was cancelled by user');
        // Don't set error for user cancellation
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Google sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithApple() async {
    debugPrint('AuthProvider: Attempting Apple sign in');
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithApple();

      if (user != null) {
        _currentUser = user;
        debugPrint('AuthProvider: Apple sign in successful');

        // Analytics
        await AnalyticsManager.instance.logLogin('apple');
        await AnalyticsManager.instance.setUserId(user.id);
        await AnalyticsManager.instance.setUserProperty(
          name: 'user_role',
          value: user.role.toString().split('.').last,
        );

        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Apple sign in was cancelled by user');
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Apple sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserRole(UserRole role) async {
    if (_currentUser == null) {
      debugPrint('AuthProvider: Cannot update role - no current user');
      return false;
    }

    debugPrint('AuthProvider: Updating user role to: $role');
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.updateUserRole(_currentUser!.id, role);
      _currentUser = _currentUser!.copyWith(role: role);

      // Analytics
      await AnalyticsManager.instance.logEvent(
        name: 'role_selected',
        parameters: {'role': role.toString().split('.').last},
      );

      await AnalyticsManager.instance.setUserProperty(
        name: 'user_role',
        value: role.toString().split('.').last,
      );

      debugPrint('AuthProvider: Role updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Role update error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    debugPrint('AuthProvider: Sending password reset email to: $email');
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      debugPrint('AuthProvider: Password reset email sent successfully');
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Password reset error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    debugPrint('AuthProvider: Signing out user');
    _setLoading(true);

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _clearError();
      debugPrint('AuthProvider: Sign out successful');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Sign out error: $e');
      _setError(e.toString());
      // Force clear user even if sign out fails
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void updateUser(UserModel user) {
    debugPrint('AuthProvider: Updating user data: ${user.name}');
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (kDebugMode) {
        debugPrint('AuthProvider: Loading state changed to: $loading');
      }
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    debugPrint('AuthProvider: Error set: $error');
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      debugPrint('AuthProvider: Error cleared');
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Debug method to check current state
  void printDebugInfo() {
    debugPrint('''
AuthProvider Debug Info:
- Initialized: $_isInitialized
- Loading: $_isLoading  
- Has User: ${_currentUser != null}
- User ID: ${_currentUser?.id}
- User Name: ${_currentUser?.name}
- User Role: ${_currentUser?.role}
- Error: $_error
''');
  }
}