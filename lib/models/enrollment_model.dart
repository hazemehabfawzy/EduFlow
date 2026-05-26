// lib/models/enrollment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a student's enrollment in a course.
/// Stored under /enrollments/{enrollmentId}.
class EnrollmentModel {
  final String id;
  final String userId;
  final String courseId;
  final List<String> completedLessonIds; // lesson IDs the student finished
  final double progress;                 // 0.0 – 1.0
  final DateTime enrolledAt;
  final DateTime lastAccessedAt;

  const EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    this.completedLessonIds = const [],
    this.progress = 0.0,
    required this.enrolledAt,
    required this.lastAccessedAt,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      completedLessonIds: List<String>.from(map['completedLessonIds'] ?? []),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      enrolledAt: (map['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastAccessedAt:
          (map['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'courseId': courseId,
    'completedLessonIds': completedLessonIds,
    'progress': progress,
    'enrolledAt': Timestamp.fromDate(enrolledAt),
    'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
  };

  bool get isCompleted => progress >= 1.0;

  int get completedCount => completedLessonIds.length;
}