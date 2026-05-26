// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/enrollment_model.dart';

/// Single point of access for all Firestore operations.
/// Screens and providers call this service — never FirebaseFirestore directly.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _courses     => _db.collection('courses');
  CollectionReference get _lessons     => _db.collection('lessons');
  CollectionReference get _enrollments => _db.collection('enrollments');
  CollectionReference get _quizzes     => _db.collection('quizzes');

  // ══════════════════════════════════════════════════════════════════════════
  // COURSES
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream of ALL courses (used by Home screen).
  Stream<List<CourseModel>> streamAllCourses() {
    return _courses
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Stream of featured courses only.
  Stream<List<CourseModel>> streamFeaturedCourses() {
    return _courses
        .where('isFeatured', isEqualTo: true)
        .limit(6)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Stream of courses filtered by category.
  Stream<List<CourseModel>> streamCoursesByCategory(String category) {
    return _courses
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Fetch a single course by ID (one-time read).
  Future<CourseModel?> fetchCourse(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LESSONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream of all lessons for a course, ordered by [order] field.
  Stream<List<LessonModel>> streamLessons(String courseId) {
    return _lessons
        .where('courseId', isEqualTo: courseId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LessonModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// One-time fetch of course lessons (used by detail screen initial load).
  Future<List<LessonModel>> fetchLessons(String courseId) async {
    final snap = await _lessons
        .where('courseId', isEqualTo: courseId)
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => LessonModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENROLLMENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Check if a user is already enrolled in a course.
  Future<EnrollmentModel?> getEnrollment({
    required String userId,
    required String courseId,
  }) async {
    final snap = await _enrollments
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return EnrollmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Stream enrollment for real-time progress updates on Course Detail screen.
  Stream<EnrollmentModel?> streamEnrollment({
    required String userId,
    required String courseId,
  }) {
    return _enrollments
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return EnrollmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Enroll a user in a course. Creates the enrollment document.
  Future<EnrollmentModel> enrollUser({
    required String userId,
    required String courseId,
  }) async {
    final existing = await getEnrollment(userId: userId, courseId: courseId);
    if (existing != null) return existing; // already enrolled

    final docRef = _enrollments.doc();
    final enrollment = EnrollmentModel(
      id: docRef.id,
      userId: userId,
      courseId: courseId,
      enrolledAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
    );

    await docRef.set(enrollment.toMap());

    // Increment totalStudents on the course document
    await _courses.doc(courseId).update({
      'totalStudents': FieldValue.increment(1),
    });

    return enrollment;
  }

  /// Mark a lesson as completed and recalculate progress.
  Future<void> markLessonComplete({
    required String enrollmentId,
    required String lessonId,
    required int totalLessons,
    required List<String> currentCompleted,
  }) async {
    if (currentCompleted.contains(lessonId)) return; // already done

    final updated = [...currentCompleted, lessonId];
    final progress = totalLessons > 0 ? updated.length / totalLessons : 0.0;

    await _enrollments.doc(enrollmentId).update({
      'completedLessonIds': updated,
      'progress': progress,
      'lastAccessedAt': Timestamp.now(),
    });
  }

  /// Stream all enrollments for a user (used by Profile screen).
  Stream<List<EnrollmentModel>> streamUserEnrollments(String userId) {
    return _enrollments
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                EnrollmentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}