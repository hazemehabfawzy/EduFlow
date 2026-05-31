import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';

class AuthSessionService {
  static StreamSubscription<User?>? _authSubscription;

  static void startMonitoring(BuildContext context) {
    _authSubscription?.cancel();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(
      (User? user) async {
        if (user == null) {
          _authSubscription?.cancel();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.lock_clock_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Your session expired. Please sign in again.')),
                ]),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
            await Future.delayed(const Duration(seconds: 1));
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.auth, (_) => false);
            }
          }
        } else {
          try {
            await user.getIdToken(true);
          } catch (e) {
            print('[AuthSession] Token refresh failed: $e');
          }
        }
      },
      onError: (error) {
        print('[AuthSession] Auth stream error: $error');
      },
    );
  }

  static void stopMonitoring() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}
