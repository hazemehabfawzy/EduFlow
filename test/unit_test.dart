import 'package:flutter_test/flutter_test.dart';
import 'package:eduflow/models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('CourseModel Tests', () {
    test('formattedDuration handles minutes only correctly', () {
      final course = CourseModel(
        id: '1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics of Flutter',
        imageUrl: 'https://example.com/image.png',
        instructorName: 'Jane Doe',
        durationMinutes: 45,
        createdAt: DateTime.now(),
      );
      expect(course.formattedDuration, equals('45m'));
    });

    test('formattedDuration handles hours only correctly', () {
      final course = CourseModel(
        id: '2',
        title: 'Intermediate Flutter',
        description: 'Learn intermediate concepts of Flutter',
        imageUrl: 'https://example.com/image.png',
        instructorName: 'Jane Doe',
        durationMinutes: 120,
        createdAt: DateTime.now(),
      );
      expect(course.formattedDuration, equals('2h'));
    });

    test('formattedDuration handles hours and minutes correctly', () {
      final course = CourseModel(
        id: '3',
        title: 'Advanced Flutter',
        description: 'Learn advanced concepts of Flutter',
        imageUrl: 'https://example.com/image.png',
        instructorName: 'Jane Doe',
        durationMinutes: 155,
        createdAt: DateTime.now(),
      );
      expect(course.formattedDuration, equals('2h 35m'));
    });

    test('fromMap creates CourseModel correctly with default values', () {
      final now = DateTime.now();
      final map = {
        'title': 'Test Course',
        'description': 'Test Description',
        'imageUrl': 'https://example.com/test.png',
        'instructorName': 'John Smith',
        'rating': 4.5,
        'totalLessons': 10,
        'totalStudents': 100,
        'category': 'Development',
        'level': 'Intermediate',
        'durationMinutes': 90,
        'isFeatured': true,
        'createdAt': Timestamp.fromDate(now),
      };

      final course = CourseModel.fromMap(map, 'test_id');

      expect(course.id, equals('test_id'));
      expect(course.title, equals('Test Course'));
      expect(course.description, equals('Test Description'));
      expect(course.imageUrl, equals('https://example.com/test.png'));
      expect(course.instructorName, equals('John Smith'));
      expect(course.rating, equals(4.5));
      expect(course.totalLessons, equals(10));
      expect(course.totalStudents, equals(100));
      expect(course.category, equals('Development'));
      expect(course.level, equals('Intermediate'));
      expect(course.durationMinutes, equals(90));
      expect(course.isFeatured, isTrue);
      expect(course.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });
}
