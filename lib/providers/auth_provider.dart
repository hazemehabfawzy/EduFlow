// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provides authentication state to the entire widget tree via [ChangeNotifier].
///
/// Screens listen to [isLoading], [currentUser], and [errorMessage]
/// without touching Firebase directly.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────

  UserModel? get currentUser    => _currentUser;
  bool       get isLoading      => _isLoading;
  String?    get errorMessage   => _errorMessage;
  bool       get isAuthenticated => _currentUser != null;

  /// Exposes the raw Firebase auth-state stream (used by SplashScreen).
  Stream get authStateStream => _authService.authStateChanges;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _currentUser = await _authService.fetchCurrentUserModel();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Returns true on success, false on failure (error is in [errorMessage]).
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      _currentUser = await _authService.signUp(
        name: name, email: email, password: password, role: role,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      _currentUser = await _authService.signIn(
        email: email, password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Returns a success message string, or throws with an error message.
  Future<String> sendPasswordReset(String email) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
      return 'Password reset email sent! Check your inbox.';
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = msg;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _clearError();
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
