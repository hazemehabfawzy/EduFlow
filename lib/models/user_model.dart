// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a SkillNest user stored in Firestore under /users/{uid}.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role; // 'student' | 'admin'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = 'student',
    required this.createdAt,
  });

  // ── Firestore serialization ─────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      role: map['role'] as String? ?? 'student',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  bool get isAdmin => role == 'admin';
}
