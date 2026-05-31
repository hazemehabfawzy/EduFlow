// lib/services/firestore_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/enrollment_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';


/// Single point of access for all Firestore operations.
/// Screens and providers call this service — never FirebaseFirestore directly.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _courses => _db.collection('courses');
  CollectionReference get _lessons => _db.collection('lessons');
  CollectionReference get _enrollments => _db.collection('enrollments');
  CollectionReference get _quizzes => _db.collection('quizzes');

  // ══════════════════════════════════════════════════════════════════════════
  // COURSES
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream of ALL courses (used by Home screen).
  Stream<List<CourseModel>> streamAllCourses() {
    return _courses.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamAllCourses error: $error');
      return <CourseModel>[];
    });
  }

  /// Stream of featured courses only.
  Stream<List<CourseModel>> streamFeaturedCourses() {
    return _courses
        .where('isFeatured', isEqualTo: true)
        .limit(6)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamFeaturedCourses error: $error');
      return <CourseModel>[];
    });
  }

  /// Stream of courses filtered by category.
  Stream<List<CourseModel>> streamCoursesByCategory(String category) {
    return _courses.where('category', isEqualTo: category).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamCoursesByCategory error: $error');
      return <CourseModel>[];
    });
  }

  /// Fetch a single course by ID (one-time read).
  Future<CourseModel?> fetchCourse(String courseId) async {
    try {
      final doc = await _courses.doc(courseId).get();
      if (!doc.exists) return null;
      return CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('[Firestore] fetchCourse error: $e');
      return null;
    }
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
            .map((d) =>
                LessonModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamLessons error: $error');
      return <LessonModel>[];
    });
  }

  /// One-time fetch of course lessons (used by detail screen initial load).
  Future<List<LessonModel>> fetchLessons(String courseId) async {
    try {
      final snap = await _lessons
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();
      return snap.docs
          .map((d) => LessonModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      print('[Firestore] fetchLessons error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENROLLMENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Check if a user is already enrolled in a course.
  Future<EnrollmentModel?> getEnrollment({
    required String userId,
    required String courseId,
  }) async {
    try {
      final snap = await _enrollments
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return EnrollmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('[Firestore] getEnrollment error: $e');
      return null;
    }
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
      return EnrollmentModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }).handleError((error) {
      print('[Firestore] streamEnrollment error: $error');
      return null;
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

    // ── NEW: Get student name and notify teacher ──
    try {
      final userDoc =
          await _db.collection('users').doc(userId).get();
      final studentName = userDoc.data()?['name'] as String? ??
          'A student';
      final courseDoc = await _courses.doc(courseId).get();
      final courseData =
          courseDoc.data() as Map<String, dynamic>?;
      final courseTitle =
          courseData?['title'] as String? ?? 'the course';
      final courseImage =
          courseData?['imageUrl'] as String?;

      unawaited(notifyTeacherNewEnrollment(
        courseId: courseId,
        courseTitle: courseTitle,
        studentName: studentName,
        studentId: userId,
        courseImageUrl: courseImage,
      ));
    } catch (e) {
      print('[Firestore] enrollment notification error: $e');
    }

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
    return _enrollments.where('userId', isEqualTo: userId).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                EnrollmentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamUserEnrollments error: $error');
      return <EnrollmentModel>[];
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch user profile details.
  Future<UserModel?> fetchUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('[Firestore] fetchUser error: $e');
      return null;
    }
  }

  /// Add a new course.
  Future<void> addCourse(CourseModel course) async {
    await _courses.doc(course.id).set(course.toMap());

    // ── NEW: Notify all students ──
    unawaited(notifyAllStudentsNewCourse(
      courseId: course.id,
      courseTitle: course.title,
      instructorName: course.instructorName,
      imageUrl: course.imageUrl,
    ));
  }

  /// Delete a course and all associated lessons, quizzes, and enrollments.
  Future<void> deleteCourse(String courseId) async {
    // 1. Delete course document
    await _courses.doc(courseId).delete();

    // 2. Delete lessons associated with this course
    final lessonsSnap =
        await _lessons.where('courseId', isEqualTo: courseId).get();
    for (var doc in lessonsSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Delete quizzes associated with this course
    final quizzesSnap =
        await _quizzes.where('courseId', isEqualTo: courseId).get();
    for (var doc in quizzesSnap.docs) {
      await doc.reference.delete();
    }

    // 4. Delete enrollments associated with this course
    final enrollmentsSnap =
        await _enrollments.where('courseId', isEqualTo: courseId).get();
    for (var doc in enrollmentsSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// Stream all enrollments for a specific course.
  Stream<List<EnrollmentModel>> streamCourseEnrollments(String courseId) {
    return _enrollments.where('courseId', isEqualTo: courseId).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                EnrollmentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamCourseEnrollments error: $error');
      return <EnrollmentModel>[];
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEACHER & ADDITIONAL ADMIN OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream all courses for a specific teacher.
  Stream<List<CourseModel>> streamTeacherCourses(String instructorName) {
    return _courses
        .where('instructorName', isEqualTo: instructorName)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                CourseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()).handleError((error) {
      print('[Firestore] streamTeacherCourses error: $error');
      return <CourseModel>[];
    });
  }

  /// Stream all users.
  Stream<List<UserModel>> streamUsers() {
    return _db.collection('users').snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList())
        .handleError((error) {
      print('[Firestore] streamUsers error: $error');
      return <UserModel>[];
    });
  }

  /// Update a user's role.
  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection('users').doc(uid).update({'role': newRole});
  }

  /// Toggle feature flag for a course.
  Future<void> toggleCourseFeatured(String courseId, bool isFeatured) async {
    await _courses.doc(courseId).update({'isFeatured': isFeatured});
  }

  /// Aggregate counts for analytics
  Future<int> countUsers() async {
    try {
      final snap = await _db.collection('users').count().get();
      return snap.count ?? 0;
    } catch (e) {
      print('[Firestore] countUsers error: $e');
      return 0;
    }
  }

  Future<int> countCourses() async {
    try {
      final snap = await _courses.count().get();
      return snap.count ?? 0;
    } catch (e) {
      print('[Firestore] countCourses error: $e');
      return 0;
    }
  }

  Future<int> countEnrollments() async {
    try {
      final snap = await _enrollments.count().get();
      return snap.count ?? 0;
    } catch (e) {
      print('[Firestore] countEnrollments error: $e');
      return 0;
    }
  }

  Future<void> submitCourseRating({
    required String courseId,
    required String userId,
    required double rating,
  }) async {
    try {
      final ratingsRef = _db
          .collection('courses')
          .doc(courseId)
          .collection('ratings')
          .doc(userId);

      await ratingsRef.set({
        'userId': userId,
        'rating': rating,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      final allRatings = await _db
          .collection('courses')
          .doc(courseId)
          .collection('ratings')
          .get();

      if (allRatings.docs.isEmpty) return;

      final total = allRatings.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      final average = total / allRatings.docs.length;

      await _courses.doc(courseId).update({
        'rating': double.parse(average.toStringAsFixed(1)),
      });

      // Get student name for the notification
      try {
        final userDoc =
            await _db.collection('users').doc(userId).get();
        final studentName = userDoc.data()?['name'] as String? ??
            'A student';
        final courseDoc = await _courses.doc(courseId).get();
        final courseTitle =
            (courseDoc.data() as Map<String, dynamic>?)?['title']
                as String? ?? 'the course';

        unawaited(notifyTeacherNewRating(
          courseId: courseId,
          courseTitle: courseTitle,
          studentName: studentName,
          rating: rating,
        ));
      } catch (e) {
        print('[Firestore] rating notification error: $e');
      }
    } catch (e) {
      print('[FirestoreService] submitCourseRating error: $e');
    }
  }

  Future<double?> getUserRating({
    required String courseId,
    required String userId,
  }) async {
    try {
      final doc = await _db
          .collection('courses')
          .doc(courseId)
          .collection('ratings')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return (doc.data()?['rating'] as num?)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> streamCourseRatings(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('ratings')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error) {
      print('[Firestore] streamCourseRatings error: $error');
      return <Map<String, dynamic>>[];
    });
  }

  // ══════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════

  CollectionReference get _notifications =>
      _db.collection('notifications');

  /// Stream notifications for a specific user, newest first
  Stream<List<NotificationModel>> streamUserNotifications(
      String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList())
        .handleError((e) {
      print('[Firestore] streamUserNotifications error: $e');
      return <NotificationModel>[];
    });
  }

  /// Stream only unread count — used for bell badge
  Stream<int> streamUnreadCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((e) => 0);
  }

  /// Mark a single notification as read
  Future<void> markNotificationRead(
      String notificationId) async {
    try {
      await _notifications
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('[Firestore] markNotificationRead error: $e');
    }
  }

  /// Mark ALL notifications as read for a user
  Future<void> markAllNotificationsRead(
      String userId) async {
    try {
      final batch = _db.batch();
      final snap = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('[Firestore] markAllNotificationsRead error: $e');
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(
      String notificationId) async {
    try {
      await _notifications.doc(notificationId).delete();
    } catch (e) {
      print('[Firestore] deleteNotification error: $e');
    }
  }

  /// Create a notification document in Firestore
  /// This is the SINGLE method all triggers call
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? imageUrl,
    String? courseId,
    required String receiverRole,
  }) async {
    try {
      await _notifications.add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'courseId': courseId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'receiverRole': receiverRole,
      });
    } catch (e) {
      print('[Firestore] createNotification error: $e');
    }
  }

  /// Called when teacher publishes a new course —
  /// notifies ALL students
  Future<void> notifyAllStudentsNewCourse({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    String? imageUrl,
  }) async {
    try {
      final studentsSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final batch = _db.batch();
      for (final doc in studentsSnap.docs) {
        final notifRef = _notifications.doc();
        batch.set(notifRef, {
          'userId': doc.id,
          'type': 'new_course',
          'title': '📚 New Course Available!',
          'body':
              '$instructorName just published "$courseTitle"',
          'imageUrl': imageUrl,
          'courseId': courseId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'receiverRole': 'student',
        });
      }
      await batch.commit();
    } catch (e) {
      print('[Firestore] notifyAllStudentsNewCourse error: $e');
    }
  }

  /// Called when student enrolls — notifies the teacher
  Future<void> notifyTeacherNewEnrollment({
    required String courseId,
    required String courseTitle,
    required String studentName,
    required String studentId,
    String? courseImageUrl,
  }) async {
    try {
      // Find the teacher who owns this course
      final courseDoc =
          await _courses.doc(courseId).get();
      if (!courseDoc.exists) return;

      final instructorName =
          (courseDoc.data() as Map<String, dynamic>)['instructorName']
              as String?;
      if (instructorName == null) return;

      final teacherSnap = await _db
          .collection('users')
          .where('name', isEqualTo: instructorName)
          .where('role', isEqualTo: 'teacher')
          .limit(1)
          .get();

      if (teacherSnap.docs.isEmpty) return;
      final teacherId = teacherSnap.docs.first.id;

      await createNotification(
        userId: teacherId,
        type: 'new_enrollment',
        title: '🎉 New Student Enrolled!',
        body: '$studentName enrolled in "$courseTitle"',
        imageUrl: courseImageUrl,
        courseId: courseId,
        receiverRole: 'teacher',
      );
    } catch (e) {
      print('[Firestore] notifyTeacherNewEnrollment error: $e');
    }
  }

  /// Called when student completes a course —
  /// notifies the student themselves
  Future<void> notifyStudentCourseComplete({
    required String studentId,
    required String courseTitle,
    required String courseId,
    String? imageUrl,
  }) async {
    await createNotification(
      userId: studentId,
      type: 'course_complete',
      title: '🏆 Course Completed!',
      body:
          'Amazing! You completed "$courseTitle". Rate it to help others.',
      imageUrl: imageUrl,
      courseId: courseId,
      receiverRole: 'student',
    );
  }

  /// Called when student submits a rating —
  /// notifies the teacher
  Future<void> notifyTeacherNewRating({
    required String courseId,
    required String courseTitle,
    required String studentName,
    required double rating,
  }) async {
    try {
      final courseDoc =
          await _courses.doc(courseId).get();
      if (!courseDoc.exists) return;

      final data =
          courseDoc.data() as Map<String, dynamic>;
      final instructorName =
          data['instructorName'] as String?;
      if (instructorName == null) return;

      final teacherSnap = await _db
          .collection('users')
          .where('name', isEqualTo: instructorName)
          .where('role', isEqualTo: 'teacher')
          .limit(1)
          .get();

      if (teacherSnap.docs.isEmpty) return;
      final teacherId = teacherSnap.docs.first.id;

      await createNotification(
        userId: teacherId,
        type: 'new_rating',
        title: '⭐ New Rating Received!',
        body:
            '$studentName rated "$courseTitle" ${rating.toInt()}/5 stars',
        courseId: courseId,
        receiverRole: 'teacher',
      );
    } catch (e) {
      print('[Firestore] notifyTeacherNewRating error: $e');
    }
  }
}
