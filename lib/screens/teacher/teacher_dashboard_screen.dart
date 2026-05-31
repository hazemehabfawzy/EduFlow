// lib/screens/teacher/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_model.dart';
import '../../models/enrollment_model.dart';
import '../../widgets/course_enrollments_sheet.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../services/auth_session_service.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddLessonSheet(BuildContext context, CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddLessonSheet(course: course),
    );
  }

  void _showLessonsSheet(BuildContext context, CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ViewLessonsSheet(course: course),
    );
  }

  void _showEditCourseSheet(BuildContext context, CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditCourseSheet(course: course),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthSessionService.startMonitoring(context);
      _firestoreService.repairStudentCounts();
    });
  }

  @override
  void dispose() {
    AuthSessionService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final teacherName = user?.name ?? 'Teacher';

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: StreamBuilder<List<CourseModel>>(
        stream: _firestoreService.streamTeacherCourses(teacherName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 36,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load dashboard',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];

          // Aggregate statistics dynamically
          final totalCourses = courses.length;
          final totalLessons =
              courses.fold<int>(0, (sum, c) => sum + c.totalLessons);

          return StreamBuilder<List<EnrollmentModel>>(
            stream: _firestoreService.streamAllEnrollments(),
            builder: (context, enrollSnap) {
              final enrollments = enrollSnap.data ?? [];
              final courseIds = courses.map((c) => c.id).toSet();
              
              // Calculate unique student IDs enrolled in the teacher's courses
              final teacherEnrollments = enrollments.where((e) => courseIds.contains(e.courseId));
              final totalStudents = teacherEnrollments.map((e) => e.userId).toSet().length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Gradient Header ───────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppColors.primary,
                    surfaceTintColor: AppColors.primary,
                    actions: [
                      IconButton(
                    tooltip: 'Toggle Dark Mode',
                    icon: Icon(
                      context.watch<ThemeProvider>().isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: AppColors.white,
                    ),
                    onPressed: () => context.read<ThemeProvider>().toggle(),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.white),
                    onPressed: () => _confirmSignOut(context),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF7C74FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome, $teacherName 👨‍🏫',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your courses and view student progress.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Statistics Cards Grid ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.85,
                    children: [
                      _buildStatCard('My Courses', totalCourses.toString(),
                          Icons.school_rounded, AppColors.primary, isDark),
                      _buildStatCard('Total Students', totalStudents.toString(),
                          Icons.people_alt_rounded, AppColors.success, isDark),
                      _buildStatCard(
                          'Total Lessons',
                          totalLessons.toString(),
                          Icons.play_circle_fill_rounded,
                          AppColors.accent,
                          isDark),
                    ],
                  ),
                ),
              ),

              // ── Section Header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Curated Courses',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalCourses active',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Courses List ───────────────────────────────────────────
              if (courses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.class_outlined,
                                size: 64, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No courses created yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to publish your first course!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = courses[index];
                        return _buildCourseRowItem(course, isDark)
                            .animate()
                            .fadeIn(
                                duration: 350.ms,
                                delay: Duration(milliseconds: 50 * index))
                            .slideY(begin: 0.05);
                      },
                      childCount: courses.length,
                    ),
                  ),
                ),
            ],
          );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text(
          'Add Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        onPressed: () => _showAddCourseSheet(context, teacherName),
      )
          .animate()
          .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRowItem(CourseModel course, bool isDark) {
    final levelColor = _getLevelColor(course.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left border indicator corresponding to level
                Container(
                  width: 5,
                  color: levelColor,
                ),
                // Course Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(course.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Course Info
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                course.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                course.level,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: levelColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('enrollments')
                                  .where('courseId', isEqualTo: course.id)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.docs.length ?? course.totalStudents;
                                return Row(
                                  children: [
                                    const Icon(Icons.people_alt_rounded,
                                        size: 12, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$count stud.',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Row(
                              children: [
                                const Icon(Icons.play_circle_fill_rounded,
                                    size: 12, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  '${course.totalLessons} less.',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Text(
                              course.formattedDuration,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                // Edit Course button — add above the Add Lesson / View Lessons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(
                            color: AppColors.warning, width: 1.5),
                        foregroundColor: AppColors.warning,
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        'Edit Course',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _showEditCourseSheet(context, course),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('Add Lesson',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () =>
                            _showAddLessonSheet(context, course),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(
                              color: AppColors.accent, width: 1.5),
                          foregroundColor: AppColors.accent,
                        ),
                        icon: const Icon(Icons.list_rounded, size: 16),
                        label: Text('View Lessons',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () =>
                            _showLessonsSheet(context, course),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                    label: Text('Track Students & Ratings',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    onPressed: () =>
                        CourseEnrollmentsSheet.show(context, course),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _showAddCourseSheet(BuildContext context, String teacherName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCourseSheet(teacherName: teacherName),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<NotificationProvider>().stopListening();
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD COURSE BOTTOM SHEET FOR TEACHERS
// ─────────────────────────────────────────────────────────────────────────────
class _AddCourseSheet extends StatefulWidget {
  final String teacherName;
  const _AddCourseSheet({required this.teacherName});

  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80',
  );
  final _durationCtrl = TextEditingController(text: '120');

  String _selectedCategory = 'Development';
  String _selectedLevel = 'Beginner';
  bool _isFeatured = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Data Science'
  ];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final teacherUid = context.read<AuthProvider>().currentUser?.uid ?? '';

    // Slugify course title for a readable ID and append timestamp
    final courseId =
        '${_titleCtrl.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';

    final course = CourseModel(
      id: courseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: _imgCtrl.text.trim(),
      instructorName: widget.teacherName,
      rating: 4.8, // Set a beautiful default initial rating
      totalLessons: 0,
      totalStudents: 0,
      category: _selectedCategory,
      level: _selectedLevel,
      durationMinutes: int.parse(_durationCtrl.text),
      isFeatured: _isFeatured,
      createdAt: DateTime.now(),
      teacherId: teacherUid,
    );

    try {
      await _firestoreService.addCourse(course);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      Text('Course "${course.title}" created successfully!')),
            ],
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.white,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Course ➕',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Course Title',
                      hint: 'e.g. Flutter Masterclass 2026',
                      controller: _titleCtrl,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Course Description',
                      hint: 'Describe what students will master...',
                      controller: _descCtrl,
                      prefixIcon: Icons.description_rounded,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Duration (Minutes)',
                            hint: '120',
                            controller: _durationCtrl,
                            prefixIcon: Icons.schedule_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) {
                                return 'Must be a number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Featured Course',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isFeatured ? 'Yes ⭐' : 'No',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isFeatured
                                            ? AppColors.warning
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: _isFeatured,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (val) =>
                                          setState(() => _isFeatured = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Thumbnail Image URL',
                      hint: 'Enter unslash or absolute image web url',
                      controller: _imgCtrl,
                      prefixIcon: Icons.image_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Image URL is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(
                                        Icons.arrow_drop_down_rounded),
                                    dropdownColor: isDark
                                        ? AppColors.cardDark
                                        : AppColors.white,
                                    items: _categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCategory = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedLevel,
                                    isExpanded: true,
                                    icon: const Icon(
                                        Icons.arrow_drop_down_rounded),
                                    dropdownColor: isDark
                                        ? AppColors.cardDark
                                        : AppColors.white,
                                    items: _levels.map((l) {
                                      return DropdownMenuItem(
                                        value: l,
                                        child: Text(
                                          l,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedLevel = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      label: 'Publish Course',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLessonSheet extends StatefulWidget {
  final CourseModel course;
  const _AddLessonSheet({required this.course});

  @override
  State<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<_AddLessonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _orderCtrl = TextEditingController(text: '1');
  bool _isPreview = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _videoUrlCtrl.dispose();
    _durationCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String videoUrl = _videoUrlCtrl.text.trim();
      if (videoUrl.isNotEmpty && !videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
        videoUrl = 'https://$videoUrl';
      }
      final docRef =
          FirebaseFirestore.instance.collection('lessons').doc();
      await docRef.set({
        'id': docRef.id,
        'courseId': widget.course.id,
        'title': _titleCtrl.text.trim(),
        'videoUrl': videoUrl,
        'notes': _notesCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 1,
        'durationMinutes':
            int.tryParse(_durationCtrl.text) ?? 30,
        'isPreview': _isPreview,
      });

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .update(
              {'totalLessons': FieldValue.increment(1)});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Lesson "${_titleCtrl.text}" added successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add lesson: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add New Lesson ➕',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text('Course: ${widget.course.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(children: [
                  CustomTextField(
                    label: 'Lesson Title',
                    hint: 'e.g. Introduction to Flutter Widgets',
                    controller: _titleCtrl,
                    prefixIcon: Icons.title_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Lesson Notes',
                    hint:
                        'What will students learn in this lesson?',
                    controller: _notesCtrl,
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.isEmpty
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Video URL (optional)',
                    hint: 'https://...',
                    controller: _videoUrlCtrl,
                    prefixIcon:
                        Icons.play_circle_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Order',
                        hint: '1',
                        controller: _orderCtrl,
                        prefixIcon:
                            Icons.format_list_numbered_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'Duration (min)',
                        hint: '30',
                        controller: _durationCtrl,
                        prefixIcon: Icons.schedule_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(children: [
                      const Icon(Icons.lock_open_rounded,
                          color: AppColors.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Free Preview',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w600)),
                            Text(
                                'Allow non-enrolled students to watch',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors
                                        .textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPreview,
                        activeColor: AppColors.accent,
                        onChanged: (val) => setState(
                            () => _isPreview = val),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Add Lesson',
                    isLoading: _isLoading,
                    onPressed:
                        _isLoading ? null : _submit,
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewLessonsSheet extends StatelessWidget {
  final CourseModel course;
  const _ViewLessonsSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final firestoreService = FirestoreService();

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Lessons — ${course.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: StreamBuilder<List<LessonModel>>(
              stream:
                  firestoreService.streamLessons(course.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 36,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Failed to load lessons',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final lessons = snapshot.data ?? [];
                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                            Icons.video_library_outlined,
                            size: 48,
                            color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No lessons yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors
                                    .textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final lesson = lessons[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text('${lesson.order}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(lesson.title,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600)),
                              Text(
                                '${lesson.durationMinutes}min'
                                '${lesson.isPreview ? " · Free Preview" : ""}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors
                                        .textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.quiz_rounded,
                                  color: AppColors.primary,
                                  size: 18),
                              tooltip: 'Manage Quiz',
                              onPressed: () {
                                Navigator.of(context).pop();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _ManageQuizSheet(
                                    courseId: course.id,
                                    lesson: lesson,
                                  ),
                                );
                              },
                            ),
                            // Edit lesson button
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: AppColors.warning, size: 18),
                              tooltip: 'Edit Lesson',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _EditLessonSheet(
                                    lesson: lesson,
                                    courseId: course.id,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 18),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('lessons')
                                    .doc(lesson.id)
                                    .delete();
                                await FirebaseFirestore.instance
                                    .collection('courses')
                                    .doc(course.id)
                                    .update({
                                  'totalLessons':
                                      FieldValue.increment(-1)
                                });
                              },
                            ),
                          ],
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageQuizSheet extends StatefulWidget {
  final String courseId;
  final LessonModel lesson;
  const _ManageQuizSheet({required this.courseId, required this.lesson});

  @override
  State<_ManageQuizSheet> createState() => _ManageQuizSheetState();
}

class _ManageQuizSheetState extends State<_ManageQuizSheet> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quiz Manager 📝',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('Lesson: ${widget.lesson.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: () => _showAddQuestionDialog(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Questions list
          Expanded(
            child: StreamBuilder<List<QuizModel>>(
              stream: _firestoreService.streamLessonQuizzes(widget.lesson.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 36,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Failed to load quizzes',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                final quizzes = snapshot.data ?? [];
                if (quizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_outlined,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No quiz questions yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap + to add MCQ questions',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final q = quizzes[i];
                    final optionLetters = ['A', 'B', 'C', 'D'];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Q${q.order}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error, size: 18),
                                onPressed: () =>
                                    _firestoreService.deleteQuizQuestion(q.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(q.question,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          ...List.generate(q.options.length, (oi) {
                            final isCorrect = oi == q.correctAnswer;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? AppColors.success.withOpacity(0.15)
                                          : AppColors.textHint.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                          oi < 4 ? optionLetters[oi] : '${oi + 1}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isCorrect
                                                  ? AppColors.success
                                                  : AppColors.textSecondary)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(q.options[oi],
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: isCorrect
                                              ? AppColors.success
                                              : null,
                                          fontWeight: isCorrect
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        )),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.success, size: 16),
                                ],
                              ),
                            );
                          }),
                          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline,
                                      color: AppColors.info, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(q.explanation!,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddQuizQuestionSheet(
        courseId: widget.courseId,
        lessonId: widget.lesson.id,
      ),
    );
  }
}

class _AddQuizQuestionSheet extends StatefulWidget {
  final String courseId;
  final String lessonId;
  const _AddQuizQuestionSheet({required this.courseId, required this.lessonId});

  @override
  State<_AddQuizQuestionSheet> createState() => _AddQuizQuestionSheetState();
}

class _AddQuizQuestionSheetState extends State<_AddQuizQuestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _optionACrl = TextEditingController();
  final _optionBCtrl = TextEditingController();
  final _optionCCtrl = TextEditingController();
  final _optionDCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');
  int _correctAnswer = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    _explanationCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('quizzes').doc();
      final quiz = QuizModel(
        id: docRef.id,
        courseId: widget.courseId,
        lessonId: widget.lessonId,
        question: _questionCtrl.text.trim(),
        options: [
          _optionACrl.text.trim(),
          _optionBCtrl.text.trim(),
          _optionCCtrl.text.trim(),
          _optionDCtrl.text.trim(),
        ],
        correctAnswer: _correctAnswer,
        order: int.tryParse(_orderCtrl.text) ?? 1,
        explanation: _explanationCtrl.text.trim().isEmpty
            ? null
            : _explanationCtrl.text.trim(),
      );

      await FirestoreService().addQuizQuestion(quiz);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quiz question added! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final optionLabels = ['A', 'B', 'C', 'D'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add MCQ Question ✏️',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Question',
                      hint: 'Enter the question...',
                      controller: _questionCtrl,
                      prefixIcon: Icons.help_outline_rounded,
                      maxLines: 2,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(4, (i) {
                      final ctrls = [_optionACrl, _optionBCtrl, _optionCCtrl, _optionDCtrl];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _correctAnswer = i),
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _correctAnswer == i
                                      ? AppColors.success
                                      : AppColors.textHint.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: _correctAnswer == i
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 18)
                                      : Text(optionLabels[i],
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSecondary)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomTextField(
                                label: 'Option ${optionLabels[i]}',
                                hint: 'Enter option ${optionLabels[i]}',
                                controller: ctrls[i],
                                prefixIcon: Icons.radio_button_unchecked_rounded,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Text('Tap the letter to mark it as the correct answer ✅',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Question Order',
                          hint: '1',
                          controller: _orderCtrl,
                          prefixIcon: Icons.format_list_numbered_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Explanation (Model Answer)',
                      hint: 'Explain why the correct answer is correct...',
                      controller: _explanationCtrl,
                      prefixIcon: Icons.lightbulb_outline_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Add Question',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                      icon: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCourseSheet extends StatefulWidget {
  final CourseModel course;
  const _EditCourseSheet({required this.course});

  @override
  State<_EditCourseSheet> createState() => _EditCourseSheetState();
}

class _EditCourseSheetState extends State<_EditCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _categoryCtrl;

  late String _selectedLevel;
  late bool _isFeatured;
  bool _isLoading = false;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    // Pre-fill all fields with existing course data
    _titleCtrl =
        TextEditingController(text: widget.course.title);
    _descriptionCtrl =
        TextEditingController(text: widget.course.description);
    _imageUrlCtrl =
        TextEditingController(text: widget.course.imageUrl);
    _priceCtrl =
        TextEditingController(text: widget.course.price.toString());
    _durationCtrl = TextEditingController(
        text: widget.course.durationMinutes.toString());
    _categoryCtrl =
        TextEditingController(text: widget.course.category);
    _selectedLevel = widget.course.level;
    _isFeatured = widget.course.isFeatured;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateCourse(
        courseId: widget.course.id,
        updates: {
          'title': _titleCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim(),
          'imageUrl': _imageUrlCtrl.text.trim(),
          'price': double.tryParse(_priceCtrl.text) ?? 0.0,
          'durationMinutes':
              int.tryParse(_durationCtrl.text) ?? 60,
          'category': _categoryCtrl.text.trim(),
          'level': _selectedLevel,
          'isFeatured': _isFeatured,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course updated successfully! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Course ✏️',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    CustomTextField(
                      label: 'Course Title',
                      hint: 'e.g. Flutter for Beginners',
                      controller: _titleCtrl,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Description
                    CustomTextField(
                      label: 'Description',
                      hint: 'What will students learn?',
                      controller: _descriptionCtrl,
                      prefixIcon: Icons.description_rounded,
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Image URL
                    CustomTextField(
                      label: 'Thumbnail URL',
                      hint: 'https://...',
                      controller: _imageUrlCtrl,
                      prefixIcon: Icons.image_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Category
                    CustomTextField(
                      label: 'Category',
                      hint: 'e.g. Business, Design, Tech',
                      controller: _categoryCtrl,
                      prefixIcon: Icons.category_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Price + Duration row
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Price (\$)',
                            hint: '0.00',
                            controller: _priceCtrl,
                            prefixIcon: Icons.attach_money_rounded,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomTextField(
                            label: 'Duration (min)',
                            hint: '60',
                            controller: _durationCtrl,
                            prefixIcon: Icons.schedule_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Level selector
                    Text(
                      'Level',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _levels.map((level) {
                        final isSelected =
                            _selectedLevel == level;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedLevel = level),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.cardDark
                                        : AppColors.surfaceLight),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Featured toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Featured Course',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Show on the Featured section',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFeatured,
                            activeColor: AppColors.warning,
                            onChanged: (val) =>
                                setState(() => _isFeatured = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    GradientButton(
                      label: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                      icon: const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLessonSheet extends StatefulWidget {
  final LessonModel lesson;
  final String courseId;
  const _EditLessonSheet(
      {required this.lesson, required this.courseId});

  @override
  State<_EditLessonSheet> createState() => _EditLessonSheetState();
}

class _EditLessonSheetState extends State<_EditLessonSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isPreview;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing lesson data
    _titleCtrl =
        TextEditingController(text: widget.lesson.title);
    _notesCtrl =
        TextEditingController(text: widget.lesson.notes);
    _videoUrlCtrl =
        TextEditingController(text: widget.lesson.videoUrl);
    _durationCtrl = TextEditingController(
        text: widget.lesson.durationMinutes.toString());
    _orderCtrl = TextEditingController(
        text: widget.lesson.order.toString());
    _isPreview = widget.lesson.isPreview;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _videoUrlCtrl.dispose();
    _durationCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateLesson(
        lessonId: widget.lesson.id,
        updates: {
          'title': _titleCtrl.text.trim(),
          'notes': _notesCtrl.text.trim(),
          'videoUrl': _videoUrlCtrl.text.trim(),
          'durationMinutes':
              int.tryParse(_durationCtrl.text) ?? 30,
          'order': int.tryParse(_orderCtrl.text) ?? 1,
          'isPreview': _isPreview,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lesson updated successfully! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Lesson ✏️',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    CustomTextField(
                      label: 'Lesson Title',
                      hint: 'e.g. Introduction to Widgets',
                      controller: _titleCtrl,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    CustomTextField(
                      label: 'Lesson Notes',
                      hint: 'What will students learn?',
                      controller: _notesCtrl,
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 4,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Video URL
                    CustomTextField(
                      label: 'Video URL',
                      hint: 'https://...',
                      controller: _videoUrlCtrl,
                      prefixIcon:
                          Icons.play_circle_outline_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Order + Duration row
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Order',
                            hint: '1',
                            controller: _orderCtrl,
                            prefixIcon:
                                Icons.format_list_numbered_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomTextField(
                            label: 'Duration (min)',
                            hint: '30',
                            controller: _durationCtrl,
                            prefixIcon: Icons.schedule_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Free preview toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_open_rounded,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free Preview',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Allow non-enrolled students to watch',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPreview,
                            activeColor: AppColors.accent,
                            onChanged: (val) =>
                                setState(() => _isPreview = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    GradientButton(
                      label: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                      icon: const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
