// lib/models/course_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a course document in Firestore under /courses/{courseId}.
class CourseModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String instructorName;
  final double rating;
  final int totalLessons;
  final int totalStudents;
  final String category;
  final String level;        // 'Beginner' | 'Intermediate' | 'Advanced'
  final int durationMinutes; // total course duration
  final bool isFeatured;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.instructorName,
    this.rating = 0.0,
    this.totalLessons = 0,
    this.totalStudents = 0,
    this.category = 'General',
    this.level = 'Beginner',
    this.durationMinutes = 0,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      instructorName: map['instructorName'] as String? ?? 'Unknown',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalLessons: (map['totalLessons'] as num?)?.toInt() ?? 0,
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'General',
      level: map['level'] as String? ?? 'Beginner',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      isFeatured: map['isFeatured'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'instructorName': instructorName,
    'rating': rating,
    'totalLessons': totalLessons,
    'totalStudents': totalStudents,
    'category': category,
    'level': level,
    'durationMinutes': durationMinutes,
    'isFeatured': isFeatured,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Formatted duration string e.g. "2h 30m"
  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}