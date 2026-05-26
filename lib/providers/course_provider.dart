// lib/providers/course_provider.dart
import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import '../services/firestore_service.dart';

/// Manages course data, search filtering, and enrollment state.
class CourseProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  // ── State ─────────────────────────────────────────────────────────────────
  List<CourseModel> _allCourses    = [];
  List<CourseModel> _filtered      = [];
  String _searchQuery              = '';
  String _selectedCategory         = 'All';
  bool _isEnrolling                = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<CourseModel> get courses          => _filtered;
  List<CourseModel> get allCourses       => _allCourses;
  String           get searchQuery       => _searchQuery;
  String           get selectedCategory  => _selectedCategory;
  bool             get isEnrolling       => _isEnrolling;
  String?          get errorMessage      => _errorMessage;

  /// Distinct categories derived from loaded courses (+ 'All' prefix).
  List<String> get categories {
    final cats = _allCourses.map((c) => c.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  // ── Stream setup ───────────────────────────────────────────────────────────

  /// Called by HomeScreen to start listening to Firestore.
  /// Returns the stream directly so the screen can use StreamBuilder if desired,
  /// but also updates internal state for search/filter.
  Stream<List<CourseModel>> streamCourses() {
    return _service.streamAllCourses().map((courses) {
      _allCourses = courses;
      _applyFilter();
      // Schedule notify after build to avoid setState during build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return _filtered;
    });
  }

  // ── Search & Filter ────────────────────────────────────────────────────────

  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilter();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _allCourses.where((c) {
      final matchesCategory =
          _selectedCategory == 'All' || c.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery) ||
          c.instructorName.toLowerCase().contains(_searchQuery) ||
          c.category.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ── Enrollments ────────────────────────────────────────────────────────────

  /// Enroll the current user in a course.
  Future<EnrollmentModel?> enroll({
    required String userId,
    required String courseId,
  }) async {
    _isEnrolling = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final enrollment = await _service.enrollUser(
        userId: userId,
        courseId: courseId,
      );
      return enrollment;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isEnrolling = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}