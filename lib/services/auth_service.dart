// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Wraps Firebase Authentication and user-document operations.
/// All methods throw [AuthException] on failure so the UI layer
/// can show meaningful messages without knowing Firebase internals.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Emits the current Firebase user (or null) whenever auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user (null if not logged in).
  User? get currentUser => _auth.currentUser;

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Creates a new account, then writes a /users/{uid} document in Firestore.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // Update Firebase Auth display name
      await user.updateDisplayName(name.trim());

      // Create Firestore user document
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: 'student',
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  /// Signs in with email + password and returns the Firestore user document.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Authentication timed out. Please check your internet connection.'),
      );

      final user = credential.user!;
      return await _fetchUserModel(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Sends a password-reset email.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Fetch User Document ────────────────────────────────────────────────────

  /// Reads /users/{uid} from Firestore and maps it to [UserModel].
  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get().timeout(
      const Duration(seconds: 6),
      onTimeout: () => throw Exception('Failed to connect to the database. Please try again.'),
    );
    if (!doc.exists) {
      throw Exception('User profile not found. Please contact support.');
    }
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Public version used by providers after app restart.
  Future<UserModel?> fetchCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserModel(user.uid);
    } catch (_) {
      return null;
    }
  }

  // ── Error Handling ─────────────────────────────────────────────────────────

  /// Maps Firebase error codes to human-friendly messages.
  Exception _handleAuthError(FirebaseAuthException e) {
    final messages = {
      'email-already-in-use':   'An account with this email already exists.',
      'invalid-email':          'Please enter a valid email address.',
      'weak-password':          'Password must be at least 6 characters.',
      'user-not-found':         'No account found with this email.',
      'wrong-password':         'Incorrect password. Please try again.',
      'too-many-requests':      'Too many attempts. Please try again later.',
      'network-request-failed': 'No internet connection. Check your network.',
      'user-disabled':          'This account has been disabled.',
      'invalid-credential':     'Invalid credentials. Please try again.',
    };

    final message = messages[e.code] ?? 'Something went wrong. Please try again.';
    return Exception(message);
  }
}
