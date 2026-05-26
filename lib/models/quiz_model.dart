// lib/models/quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// One quiz question stored under /quizzes/{quizId}.
class QuizModel {
  final String id;
  final String courseId;
  final String question;
  final List<String> options;    // exactly 4 options
  final int correctAnswer;       // 0-based index into [options]
  final int order;
  final String? explanation;     // shown after answering

  const QuizModel({
    required this.id,
    required this.courseId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.order = 1,
    this.explanation,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map, String id) {
    return QuizModel(
      id: id,
      courseId: map['courseId'] as String? ?? '',
      question: map['question'] as String? ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: (map['correctAnswer'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 1,
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'order': order,
    'explanation': explanation,
  };
}