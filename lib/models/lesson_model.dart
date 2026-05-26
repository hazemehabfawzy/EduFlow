// lib/models/lesson_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a lesson document in Firestore under /lessons/{lessonId}.
class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String videoUrl;
  final String notes;
  final int order;           // position in the course (1, 2, 3 …)
  final int durationMinutes;
  final bool isPreview;      // free preview without enrollment

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.videoUrl = '',
    this.notes = '',
    this.order = 1,
    this.durationMinutes = 0,
    this.isPreview = false,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map, String id) {
    return LessonModel(
      id: id,
      courseId: map['courseId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      order: (map['order'] as num?)?.toInt() ?? 1,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      isPreview: map['isPreview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'title': title,
    'videoUrl': videoUrl,
    'notes': notes,
    'order': order,
    'durationMinutes': durationMinutes,
    'isPreview': isPreview,
  };

  String get formattedDuration {
    if (durationMinutes == 0) return '';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}